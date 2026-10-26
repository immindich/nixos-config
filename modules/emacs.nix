{ inputs, ... }:
{
  nixpkgs.overlays = [ inputs.emacs-overlay.overlays.package ];
}
