{ config, ... }:
{
  xdg.configHome = "${config.home.homeDirectory}/config:personal";
  programs.vicinae = {
    enable = true;
    package = null;
    settings.font.normal.size = 12;
  };
  assertions = [
    {
      assertion = !(config.home.activation ? vicinae-refresh-apps);
      message = "A null Vicinae package must not add executable activation hooks.";
    }
    {
      assertion = !(config.home.sessionVariables ? VICINAE_OVERRIDES);
      message = "Immutable Vicinae settings must not export an override selector.";
    }
  ];
  nmt.script = ''
    assertFileContent "home-files/config:personal/vicinae/settings.json" ${./read-only-layer.json}
    assertPathNotExists "home-files/config:personal/vicinae/home-manager.json"
  '';
}
