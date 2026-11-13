{
  home.username = "alice";
  home.homeDirectory = "/home/alice";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  services.openlinkhub = {
    enable = true;
    dashboard.enable = true;
  };
}
