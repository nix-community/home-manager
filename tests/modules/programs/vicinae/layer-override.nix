{ config, ... }:
{
  xdg.configFile."vicinae/home-manager.json" = {
    target = "${config.home.homeDirectory}/layers/my % settings.json";
    enable = true;
  };
  programs.vicinae = {
    enable = true;
    enableMutableConfig = true;
    settings.font.normal.size = 12;
    systemd.enable = true;
    enableFirefoxIntegration = false;
  };
  nmt.script = ''
    assertFileContent "home-files/layers/my % settings.json" ${./read-only-layer.json}
    assertPathNotExists "home-files/.config/vicinae/settings.json"
    assertFileContains "home-path/etc/profile.d/hm-session-vars.sh" 'export VICINAE_OVERRIDES="${config.home.homeDirectory}/layers/my % settings.json"'
    assertFileContains "home-files/.config/systemd/user/vicinae.service" 'Environment="VICINAE_OVERRIDES=${config.home.homeDirectory}/layers/my %% settings.json"'
  '';
}
