# Shared by the vm-* scripts. Source it; don't run it.
#
# The guest is reached through the `vm` entry in ~/.ssh/config (localhost
# port 2222, key ~/.ssh/nixos-vm). hyprctl, qs, grim and wtype need the
# Hyprland session's environment, which a plain ssh login doesn't have.

set -euo pipefail

# (`export $(...)` would print the whole environment when the substitution is
# empty, i.e. before Hyprland has imported its variables; eval prints nothing)
SESSION_ENV='eval "$(systemctl --user show-environment | grep -E "^(WAYLAND_DISPLAY|HYPRLAND_INSTANCE_SIGNATURE)=" | sed "s/^/export /")"'

# Run a shell command line in the guest, inside the session environment
vm_session() {
    ssh vm "$SESSION_ENV; $*"
}

# Run a shell command line in the guest without the session environment
vm_plain() {
    ssh vm "$@"
}

vm_reachable() {
    ssh -o ConnectTimeout=2 -o BatchMode=yes vm true 2>/dev/null
}

die() {
    echo "$(basename "$0"): $*" >&2
    exit 1
}

# Whether Hyprland has imported its variables into the user session yet
# (about 16 s after boot; the quickshell service starts right after)
vm_env_ready() {
    vm_plain 'systemctl --user show-environment | grep -q "^HYPRLAND_INSTANCE_SIGNATURE="' 2>/dev/null
}

# Geometry of the bar's layer surface as "x,y wxh" (logical pixels), or
# nothing while the bar isn't mapped
vm_bar_geometry() {
    vm_env_ready || return 0
    vm_session 'hyprctl layers -j 2>/dev/null | jq -r ".. | objects | select(.namespace? == \"quickshell\") | \"\(.x),\(.y) \(.w)x\(.h)\"" | head -1' 2>/dev/null || true
}

# Wait until the bar is on screen, which also means the session environment
# is imported and Quickshell has loaded its config
vm_wait_for_bar() {
    local timeout=${1:-90}
    for _ in $(seq 1 "$timeout"); do
        [ -n "$(vm_bar_geometry)" ] && return 0
        sleep 1
    done
    return 1
}
