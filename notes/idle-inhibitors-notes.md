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

It polls both every 2 s while the menu is open. The gap is D-Bus
ScreenSaver inhibits: hypridle owns `org.freedesktop.ScreenSaver`, honors
those calls, and has no way to list them.

## Closing the gap, KDE-style (not done)

A small user service that does what kscreenlocker does, sending the calls
to logind instead of PowerDevil:

1. Set `services.hypridle.settings.general.ignore_dbus_inhibit = true` so
   hypridle doesn't claim the name.
2. The service owns `org.freedesktop.ScreenSaver` (paths `/ScreenSaver` and
   `/org/freedesktop/ScreenSaver`). On `Inhibit(app, reason)` it takes a
   logind inhibitor (`Inhibit("idle", app, reason, "block")`, keeping the fd)
   and returns a cookie. On `UnInhibit(cookie)` it closes the fd, and it does
   the same when the caller leaves the bus (NameOwnerChanged).
3. hypridle already honors logind idle inhibitors, so behavior is unchanged,
   and these entries appear in the menu's logind list with app name and
   reason.

Cost: a short Python script (needs a D-Bus library, e.g. dbus-next or
pygobject, built by Nix) and a home-manager systemd user service. Another
moving part in the idle path: if it dies, D-Bus inhibits stop working until
it restarts.

Check first whether it's needed: play a video in Firefox and run
`hyprctl clients -j | jq '.[] | {class, inhibitingIdle}'`. If Firefox
shows `inhibitingIdle: true`, it's using Wayland idle-inhibit and already
appears in the menu. To see whether anything uses the D-Bus path, run
`busctl --user monitor org.freedesktop.ScreenSaver` while it plays.
