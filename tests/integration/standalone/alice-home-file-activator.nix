{
  home.username = "alice";
  home.homeDirectory = "/home/alice";
  home.stateVersion = "24.11";
  home.file.test.text = "test";
  programs.home-manager.enable = true;

  # Enable specific file activator.
  home.fileActivator = "@fileActivator@";
}
