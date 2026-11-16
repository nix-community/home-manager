{
  imports = [ ./example-settings.nix ];
  systemd.user.startServices = "suggest";
  xdg.configHome = "/home/hm-user/custom-config";
}
