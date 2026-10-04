{ config, ... }:
{
  xdg.configHome = "${config.home.homeDirectory}/config:personal";
  programs.vicinae = {
    enable = true;
    enableMutableConfig = true;
    settings = { };
  };
  assertions = [
    {
      assertion = !(config.home.sessionVariables ? VICINAE_OVERRIDES);
      message = "Empty or disabled Vicinae override files must not export a session selector.";
    }
  ];
  nmt.script = ''
    assertPathNotExists "home-files/.config/vicinae/home-manager.json"
    assertPathNotExists "home-files/.config/vicinae/settings.json"
    assertPathNotExists "home-files/config:personal/vicinae/home-manager.json"
    assertPathNotExists "home-files/config:personal/vicinae/settings.json"
  '';
}
