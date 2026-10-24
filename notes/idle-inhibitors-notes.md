# Listing idle inhibitors: KDE vs. this setup

Notes from adding the "Also blocking idle" list to the Quickshell power menu
(2026-10-24).

## How KDE does it

Everything goes through one place: PowerDevil's PolicyAgent
(`org.kde.Solid.PowerManagement.PolicyAgent` on the session bus). The battery
applet reads its `RequestedInhibitions` property, `a(ssssu)` = what, who,
why, mode, flags (0x1 active, 0x2 allowed; `SetInhibitionAllowed` lets the
user suppress one). Inhibits reach it by:

- **org.freedesktop.ScreenSaver.Inhibit** (browsers, video players):
  kscreenlocker owns that name and forwards each call to PolicyAgent
  `AddInhibition` with the app name and reason.
- **org.freedesktop.PowerManagement.Inhibit**: implemented by PowerDevil
  itself (FdoConnector).
- **logind** (`systemd-inhibit`): PowerDevil calls `ListInhibitors`, re-reads
  it whenever logind's Manager properties change, and mirrors each one into
  its own list.
- **Wayland idle-inhibit**: *not listed*. KWin handles these internally
  (`IdleInhibition` → `input()->addIdleInhibitor`) and never reports them to
  PowerDevil.

Sources (master, 2026-10-24): powerdevil `daemon/powerdevilpolicyagent.cpp`,
`daemon/powerdevilfdoconnector.cpp`,
`applets/batterymonitor/plugin/inhibitioncontrol.cpp`; kscreenlocker
`interface.cpp`; kwin `src/idle_inhibition.cpp`.

## What the bar does

`home/quickshell/menus/PowerMenu.qml` lists:

- windows Hyprland reports with `inhibitingIdle` (Wayland idle-inhibit, or an
  `idle_inhibit` window rule). This includes the class and title, but no reason.
- logind inhibitors whose `what` includes `idle`, with who and why.

It polls both every 2 s while the menu is open. D-Bus ScreenSaver inhibits
reach it as logind inhibitors, through the bridge below.

## Closing the gap, KDE-style (done, 2026-10-24)

Firefox needed it: `busctl --user monitor org.freedesktop.ScreenSaver` showed
it calling `Inhibit("firefox", "Playing video")` and `("firefox", "Playing
audio")` on hypridle, and in the VM its window had `inhibitingIdle: false`, so
it doesn't also take a Wayland inhibitor. Before the bridge the menu showed
nothing while Firefox played. On pause it releases the video inhibit at once
and the audio one about 10 s later.

`home/screensaver-inhibit.py` (Python with Gio from pygobject3), run by the
`screensaver-inhibit` user service in `home/hypridle.nix`, does what
kscreenlocker does but sends the calls to logind instead of PowerDevil:

1. hypridle runs with `ignore_dbus_inhibit = true`, so it doesn't claim the
   name.
2. The service owns `org.freedesktop.ScreenSaver` (paths `/ScreenSaver` and
   `/org/freedesktop/ScreenSaver`). On `Inhibit(app, reason)` it takes a
   logind inhibitor (`Inhibit("idle", app, reason, "block")`, keeping the fd)
   and returns a cookie. `UnInhibit(cookie)` closes the fd, and the service
   does the same when the caller leaves the bus. Only the connection that
   took an inhibitor can release it; other cookies are ignored. An empty app
   name becomes "unknown" (logind would accept it, but it'd be a blank row).
3. hypridle honors logind idle inhibitors (it watches `BlockInhibited`), so
   behavior is unchanged, and the entries appear in the menu's logind list
   with app name and reason.

Behavior to know about:

- If the service dies, logind drops its inhibitors, and apps that already
  inhibited don't re-send, so they stop blocking idle until they inhibit
  again. systemd restarts it after 5 s. (hypridle restarting had the same
  effect before.)
- `StartServiceByName("org.freedesktop.ScreenSaver")` still fails with "not
  activatable" in a trace. That's GLib's name watcher trying auto-start
  before `GetNameOwner`; it's expected and harmless.

Tested in the VM with a second hypridle on a 15 s listener that only logs:
no inhibitor fires at 15 s; a ScreenSaver inhibit through the bridge, a
logind inhibitor, mpv's Wayland inhibitor, and Firefox playing a video each
keep it from firing, and it fires 15 s after release. The menu listed all
three kinds at once and updated as each went away.
