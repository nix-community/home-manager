{ config, pkgs, ... }:

{
  home.username = "alice";
  home.homeDirectory = "/home/alice";
  home.stateVersion = "23.11";
  home.packages = [ pkgs.hello ];
  home.file.test.text = "test";
  home.sessionVariables.EDITOR = "emacs";
  programs.bash.enable = true;
  programs.home-manager.enable = true;

  # Enable a light-weight systemd service.
  services.pueue.enable = true;

  # We focus on sd-switch since that hopefully will become the default in the
  # future.
  systemd.user.startServices = "sd-switch";
}
