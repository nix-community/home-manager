{ config, ... }:
{
  xdg.configFile."vicinae/home-manager.json" = {
    target = "${config.home.homeDirectory}/layers/vicinae:personal.json";
    enable = false;
  };
  programs.vicinae = {
    enable = true;
    mutableSettings = true;
    settings.font.normal.size = 12;
    systemd.enable = true;
    enableFirefoxIntegration = false;
  };
  assertions = [
    {
      assertion = config.systemd.user.services.vicinae.Service.Environment == [ ];
      message = "Disabled Vicinae override files must not export a service selector.";
    }
    {
      assertion = !(config.home.sessionVariables ? VICINAE_OVERRIDES);
      message = "Empty or disabled Vicinae override files must not export a session selector.";
    }
  ];
  nmt.script = ''
    assertPathNotExists "home-files/layers/vicinae:personal.json"
    assertPathNotExists "home-files/.config/vicinae/settings.json"
  '';
}
