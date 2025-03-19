{ config, pkgs, ... }:

{
  home.username = "alice";
  home.homeDirectory = "/home/alice";
  home.stateVersion = "24.11";
  programs.home-manager.enable = true;

  # Write .profile
  home.file = {
    ".profile".text = ''
      echo sourcing dotprofile
    '';
  };
}
