{
  home.username = "alice";
  home.homeDirectory = "/home/alice";
  home.stateVersion = "24.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.kitty = {
    enable = true;
    autoThemeFiles = {
      light = "GitHub";
      dark = "No Such Theme";
      noPreference = "OneDark";
    };
  };
}
