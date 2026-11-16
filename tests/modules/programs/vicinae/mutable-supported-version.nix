{ config, ... }:
{
  programs.vicinae = {
    enable = true;
    mutableSettings = true;
    package = config.lib.test.mkStubPackage {
      name = "vicinae";
      version = "0.20.6";
    };
    settings.font.normal.size = 12;
    systemd.enable = false;
    enableFirefoxIntegration = false;
  };
  nmt.script = ''
    assertFileContent "home-files/.config/vicinae/home-manager.json" ${./read-only-layer.json}
    assertPathNotExists "home-files/.config/vicinae/settings.json"
    assertFileContains "home-path/etc/profile.d/hm-session-vars.sh" 'export VICINAE_OVERRIDES="${config.home.homeDirectory}/.config/vicinae/home-manager.json"'
  '';
}
