{ ... }: {
  home.username = "alice";
  home.homeDirectory = "/home/alice";

  home.stateVersion = "24.05"; # Please read the comment before changing.

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.kitty = {
    enable = true;
    themeFile = "SpaceGray_Eighties";
  };
}
