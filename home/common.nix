{ pkgs, ... }:

{
  home.username = "isaiah";
  home.homeDirectory = "/home/isaiah";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}