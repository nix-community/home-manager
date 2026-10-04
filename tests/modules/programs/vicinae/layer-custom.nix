{ config, ... }:
{
  xdg.configHome = "${config.home.homeDirectory}/.custom";
  programs.vicinae = {
    enable = true;
    enableMutableConfig = true;
    package = null;
    settings.font.normal.size = 12;
    systemd.enable = false;
    enableFirefoxIntegration = false;
  };
  nmt.script = ''
    assertFileContent "home-files/.custom/vicinae/home-manager.json" ${./read-only-layer.json}
    assertPathNotExists "home-files/.custom/vicinae/settings.json"
    assertFileContains "home-path/etc/profile.d/hm-session-vars.sh" 'export VICINAE_OVERRIDES="${config.home.homeDirectory}/.custom/vicinae/home-manager.json"'
  '';
}
