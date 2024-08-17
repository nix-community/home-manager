{ ... }: {
  home.username = "alice";
  home.homeDirectory = "/home/alice";
  home.stateVersion = "24.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.kitty = {
    enable = true;
    themeFile = "No Such Theme";
  };
}
