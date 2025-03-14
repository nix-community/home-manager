{ config, pkgs, ... }:

{
  home.username = "alice";
  home.homeDirectory = "/home/alice";
  home.stateVersion = "24.11";
  home.packages = [ pkgs.hello ];
  home.file.test.text = "test";
  home.sessionVariables.EDITOR = "emacs";
  programs.bash.enable = true;
  programs.home-manager.enable = true;

  # Enable a light-weight systemd service.
  services.pueue.enable = true;
}
