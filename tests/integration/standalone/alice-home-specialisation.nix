{ ... }:

{
  home.username = "alice";
  home.homeDirectory = "/home/alice";
  home.stateVersion = "25.05";
  home.file.test.text = "test";
  home.sessionVariables.EDITOR = "emacs";
  programs.bash.enable = true;
  programs.home-manager.enable = true;

  specialisation.pueue.configuration = {
    # Enable a light-weight systemd service.
    services.pueue.enable = true;
  };
}
