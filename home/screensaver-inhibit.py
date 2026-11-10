"""Turn every idle inhibit into a logind idle inhibitor, skipping ignored apps.

Apps keep the screen awake in one of two ways:

- Calling Inhibit(app, reason) on org.freedesktop.ScreenSaver (Firefox,
  Chromium, Steam). This service owns that name (hypridle runs with
  ignore_dbus_inhibit) and takes a logind "idle" inhibitor for each call,
  with the app as who and the reason as why. Each is released on
  UnInhibit(cookie), or when the app that took it disconnects from the bus.

- Holding a Wayland idle inhibitor on a window (mpv, SDL games, Electron
  apps such as Claude Desktop). hypridle runs with ignore_wayland_inhibit, so
  this service polls Hyprland for windows reporting inhibitingIdle and holds
  a logind inhibitor for each, with the window class as who and its title as
  why, until the window stops inhibiting or closes.

hypridle honors logind idle inhibitors, and `systemd-inhibit --list` (and the
bar's power menu) shows them. Apps named with --ignore (a D-Bus app name or a
window class, case-insensitive) get no inhibitor: their D-Bus calls still
succeed, but nothing keeps the screen awake. ListIgnored() on
local.ScreenSaverInhibit at /IdleInhibitBridge (same bus name) returns the
ignored inhibits currently asked for, as (who, why), for the power menu; the
journal logs each one as it comes and goes. If this service exits, logind
drops every inhibitor it held.
"""

import argparse
import itertools
import json
import os
import socket
import sys

from gi.repository import Gio, GLib

BUS_NAME = "org.freedesktop.ScreenSaver"
# Apps use either path
OBJECT_PATHS = ["/ScreenSaver", "/org/freedesktop/ScreenSaver"]

# Hyprland doesn't announce inhibitor changes; idle timeouts are minutes long
WINDOW_POLL_SECONDS = 5

INTERFACE = Gio.DBusNodeInfo.new_for_xml("""
<node>
  <interface name="org.freedesktop.ScreenSaver">
    <method name="Inhibit">
      <arg name="application_name" type="s" direction="in"/>
      <arg name="reason_for_inhibit" type="s" direction="in"/>
      <arg name="cookie" type="u" direction="out"/>
    </method>
    <method name="UnInhibit">
      <arg name="cookie" type="u" direction="in"/>
    </method>
  </interface>
</node>
""").interfaces[0]

# Not part of the ScreenSaver spec: what --ignore is currently turning away
BRIDGE_PATH = "/IdleInhibitBridge"
BRIDGE_INTERFACE = Gio.DBusNodeInfo.new_for_xml("""
<node>
  <interface name="local.ScreenSaverInhibit">
    <method name="ListIgnored">
      <arg name="inhibits" type="a(ss)" direction="out"/>
    </method>
  </interface>
</node>
""").interfaces[0]


def log(message):
    print(message, file=sys.stderr, flush=True)


def hyprland_clients():
    """Hyprland's window list (`hyprctl clients -j`), read from its socket."""
    path = os.path.join(os.environ["XDG_RUNTIME_DIR"], "hypr",
                        os.environ["HYPRLAND_INSTANCE_SIGNATURE"], ".socket.sock")
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.settimeout(2)
        s.connect(path)
        s.sendall(b"j/clients")
        chunks = []
        while chunk := s.recv(65536):
            chunks.append(chunk)
    return json.loads(b"".join(chunks))


class Bridge:
    def __init__(self, session_bus, system_bus, ignored):
        self.session_bus = session_bus
        self.system_bus = system_bus
        self.ignored = {name.casefold() for name in ignored}
        self.cookies = itertools.count(1)
        # cookie -> (sender, logind fd, or None for an ignored app, who, why)
        self.inhibitors = {}
        # sender -> bus name watch id, for senders still on the bus
        self.watches = {}
        # window address -> logind fd, or None while logind is answering
        self.windows = {}
        # window address -> (class, title), for ignored windows inhibiting idle
        self.ignored_windows = {}
        self.hyprland_error = None

    def is_ignored(self, name):
        return name.casefold() in self.ignored

    def take_inhibitor(self, who, why, on_fd, on_error):
        """Ask logind for an idle inhibitor; calls on_fd(fd) or on_error(message)."""
        def done(bus, result):
            try:
                reply, fds = bus.call_with_unix_fd_list_finish(result)
            except GLib.Error as e:
                log(f"logind refused the inhibit for {who}: {e.message}")
                on_error(e.message)
                return
            on_fd(fds.steal_fds()[reply.unpack()[0]])

        self.system_bus.call_with_unix_fd_list(
            "org.freedesktop.login1", "/org/freedesktop/login1",
            "org.freedesktop.login1.Manager", "Inhibit",
            GLib.Variant("(ssss)", ("idle", who, why, "block")),
            GLib.VariantType("(h)"), Gio.DBusCallFlags.NONE, -1, None, None, done)

    def handle_bridge_call(self, connection, sender, path, interface, method, params, invocation):
        if method == "ListIgnored":
            ignored = [(who, why) for _, fd, who, why in self.inhibitors.values() if fd is None]
            ignored += list(self.ignored_windows.values())
            invocation.return_value(GLib.Variant("(a(ss))", (ignored,)))

    # org.freedesktop.ScreenSaver

    def handle_call(self, connection, sender, path, interface, method, params, invocation):
        if method == "Inhibit":
            self.inhibit(invocation, sender, *params.unpack())
        elif method == "UnInhibit":
            self.uninhibit(sender, *params.unpack())
            invocation.return_value(None)

    def inhibit(self, invocation, sender, app, reason):
        if sender not in self.watches:
            self.watches[sender] = Gio.bus_watch_name_on_connection(
                self.session_bus, sender, Gio.BusNameWatcherFlags.NONE,
                None, self.sender_vanished)

        # An empty name would be a blank row in the menu
        who = app.strip() or "unknown"

        def add(fd):
            cookie = next(self.cookies)
            self.inhibitors[cookie] = (sender, fd, who, reason)
            invocation.return_value(GLib.Variant("(u)", (cookie,)))
            return cookie

        if self.is_ignored(who):
            # Answer as usual so the app doesn't retry or complain
            cookie = add(None)
            log(f"ignored {cookie}: {who}: {reason} ({sender})")
            return

        def on_fd(fd):
            if sender not in self.watches:
                # Left the bus while logind was answering
                os.close(fd)
                return
            cookie = add(fd)
            log(f"inhibit {cookie}: {who}: {reason} ({sender})")

        self.take_inhibitor(
            who, reason, on_fd,
            lambda message: invocation.return_dbus_error(
                "org.freedesktop.DBus.Error.Failed", message))

    def uninhibit(self, sender, cookie):
        if cookie not in self.inhibitors:
            return
        owner, fd, _, _ = self.inhibitors[cookie]
        # Only the app that took an inhibitor can release it
        if owner != sender:
            log(f"ignoring uninhibit of cookie {cookie}: not held by {sender}")
            return
        del self.inhibitors[cookie]
        if fd is not None:
            os.close(fd)
        log(f"uninhibit {cookie} ({sender})")

    def sender_vanished(self, connection, sender):
        Gio.bus_unwatch_name(self.watches.pop(sender))
        for cookie, (owner, fd, _, _) in list(self.inhibitors.items()):
            if owner == sender:
                del self.inhibitors[cookie]
                if fd is not None:
                    os.close(fd)
                log(f"released {cookie}: {sender} left the bus")

    # Wayland idle inhibitors, as Hyprland reports them

    def poll_windows(self):
        try:
            clients = hyprland_clients()
        except (OSError, KeyError, ValueError) as e:
            # Keep what's held; say so once per outage
            if self.hyprland_error is None:
                log(f"can't read Hyprland's windows: {e!r}")
            self.hyprland_error = e
            return GLib.SOURCE_CONTINUE
        if self.hyprland_error is not None:
            log("reading Hyprland's windows again")
            self.hyprland_error = None

        inhibiting = {}
        ignored = {}
        for c in clients:
            if c.get("inhibitingIdle"):
                if self.is_ignored(c.get("class", "")):
                    ignored[c["address"]] = (c.get("class") or "unknown", c.get("title") or "Idle inhibitor")
                else:
                    inhibiting[c["address"]] = c

        for address in ignored.keys() - self.ignored_windows.keys():
            log(f"ignored window {address} ({ignored[address][0]})")
        for address in self.ignored_windows.keys() - ignored.keys():
            log(f"ignored window {address} stopped inhibiting")
        self.ignored_windows = ignored

        for address in [a for a in self.windows if a not in inhibiting]:
            fd = self.windows.pop(address)
            if fd is not None:
                os.close(fd)
            log(f"window {address} stopped inhibiting")

        for address, client in inhibiting.items():
            if address in self.windows:
                continue
            self.windows[address] = None
            who = client.get("class") or "unknown"
            why = client.get("title") or "Idle inhibitor"

            def on_fd(fd, address=address, who=who):
                if address in self.windows and self.windows[address] is None:
                    self.windows[address] = fd
                    log(f"window {address} ({who}) inhibits idle")
                else:
                    # Stopped inhibiting, or taken twice, while logind answered
                    os.close(fd)

            def on_error(message, address=address):
                # Try again on the next poll
                if self.windows.get(address, 0) is None:
                    del self.windows[address]

            self.take_inhibitor(who, why, on_fd, on_error)

        return GLib.SOURCE_CONTINUE


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--ignore", action="append", default=[], metavar="APP",
                        help="D-Bus app name or window class to give no inhibitor")
    args = parser.parse_args()

    session_bus = Gio.bus_get_sync(Gio.BusType.SESSION)
    system_bus = Gio.bus_get_sync(Gio.BusType.SYSTEM)
    bridge = Bridge(session_bus, system_bus, args.ignore)
    for path in OBJECT_PATHS:
        session_bus.register_object_with_closures2(path, INTERFACE, bridge.handle_call)
    session_bus.register_object_with_closures2(
        BRIDGE_PATH, BRIDGE_INTERFACE, bridge.handle_bridge_call)

    loop = GLib.MainLoop()

    # Exit with an error so systemd restarts us and tries again
    def name_lost(connection, name):
        log(f"couldn't own {name}; is hypridle still claiming it?")
        loop.quit()

    Gio.bus_own_name_on_connection(
        session_bus, BUS_NAME, Gio.BusNameOwnerFlags.DO_NOT_QUEUE,
        lambda *_: log(f"owning {BUS_NAME}"), name_lost)

    bridge.poll_windows()
    GLib.timeout_add_seconds(WINDOW_POLL_SECONDS, bridge.poll_windows)
    loop.run()
    sys.exit(1)


if __name__ == "__main__":
    main()
