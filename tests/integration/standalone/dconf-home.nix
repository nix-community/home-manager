{ pkgs, ... }:
{
  home.username = "alice";
  home.homeDirectory = "/home/alice";

  home.stateVersion = "25.11"; # Please read the comment before changing.

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  dconf.settings = {
    foo = {
      bar = 42;
    };
  };

  dconf.databases.custom = {
    foo1 = {
      bar1 = 42;
    };
  };
}
