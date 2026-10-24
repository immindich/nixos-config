"""Turn org.freedesktop.ScreenSaver inhibits into logind idle inhibitors.

Apps such as Firefox keep the screen awake by calling Inhibit(app, reason)
on org.freedesktop.ScreenSaver. hypridle can answer those itself, but it
keeps them to itself, so nothing can list them. This service owns the name
instead (hypridle runs with ignore_dbus_inhibit) and takes a logind
"idle" inhibitor for each call, with the app as who and the reason as why.
hypridle honors logind idle inhibitors, and `systemd-inhibit --list` (and the
bar's power menu) shows them.

Each inhibitor is released on UnInhibit(cookie), or when the app that took
it disconnects from the bus. If this service exits, logind drops them all.
"""

import itertools
import os
import sys

from gi.repository import Gio, GLib

BUS_NAME = "org.freedesktop.ScreenSaver"
# Apps use either path
OBJECT_PATHS = ["/ScreenSaver", "/org/freedesktop/ScreenSaver"]

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


def log(message):
    print(message, file=sys.stderr, flush=True)


class Bridge:
    def __init__(self, session_bus, system_bus):
        self.session_bus = session_bus
        self.system_bus = system_bus
        self.cookies = itertools.count(1)
        # cookie -> (sender, logind fd)
        self.inhibitors = {}
        # sender -> bus name watch id, for senders still on the bus
        self.watches = {}

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

        def done(bus, result):
            try:
                reply, fds = bus.call_with_unix_fd_list_finish(result)
            except GLib.Error as e:
                log(f"logind refused the inhibit for {who} ({sender}): {e.message}")
                invocation.return_dbus_error("org.freedesktop.DBus.Error.Failed", e.message)
                return
            fd = fds.steal_fds()[reply.unpack()[0]]
            if sender not in self.watches:
                # Left the bus while logind was answering
                os.close(fd)
                return
            cookie = next(self.cookies)
            self.inhibitors[cookie] = (sender, fd)
            log(f"inhibit {cookie}: {who}: {reason} ({sender})")
            invocation.return_value(GLib.Variant("(u)", (cookie,)))

        self.system_bus.call_with_unix_fd_list(
            "org.freedesktop.login1", "/org/freedesktop/login1",
            "org.freedesktop.login1.Manager", "Inhibit",
            GLib.Variant("(ssss)", ("idle", who, reason, "block")),
            GLib.VariantType("(h)"), Gio.DBusCallFlags.NONE, -1, None, None, done)

    def uninhibit(self, sender, cookie):
        owner, fd = self.inhibitors.get(cookie, (None, None))
        # Only the app that took an inhibitor can release it
        if owner != sender:
            log(f"ignoring uninhibit of cookie {cookie}: not held by {sender}")
            return
        del self.inhibitors[cookie]
        os.close(fd)
        log(f"uninhibit {cookie} ({sender})")

    def sender_vanished(self, connection, sender):
        Gio.bus_unwatch_name(self.watches.pop(sender))
        for cookie, (owner, fd) in list(self.inhibitors.items()):
            if owner == sender:
                del self.inhibitors[cookie]
                os.close(fd)
                log(f"released {cookie}: {sender} left the bus")


def main():
    session_bus = Gio.bus_get_sync(Gio.BusType.SESSION)
    system_bus = Gio.bus_get_sync(Gio.BusType.SYSTEM)
    bridge = Bridge(session_bus, system_bus)
    for path in OBJECT_PATHS:
        session_bus.register_object_with_closures2(path, INTERFACE, bridge.handle_call)

    loop = GLib.MainLoop()

    # Exit with an error so systemd restarts us and tries again
    def name_lost(connection, name):
        log(f"couldn't own {name}; is hypridle still claiming it?")
        loop.quit()

    Gio.bus_own_name_on_connection(
        session_bus, BUS_NAME, Gio.BusNameOwnerFlags.DO_NOT_QUEUE,
        lambda *_: log(f"owning {BUS_NAME}"), name_lost)
    loop.run()
    sys.exit(1)


if __name__ == "__main__":
    main()
