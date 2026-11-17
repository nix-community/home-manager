{ config, ... }:
{
  xdg.configFile."vicinae/home-manager.json" = {
    target = "${config.home.homeDirectory}/layers/my % settings.json";
    enable = true;
  };
  programs.vicinae = {
    enable = true;
    mutableSettings = true;
    settings.font.normal.size = 12;
    service.enable = true;
    enableFirefoxIntegration = false;
  };
  assertions = [
    {
      assertion =
        config.systemd.user.services.vicinae.Unit.X-Restart-Triggers == [
          (config.lib.file.sourceStorePath
            config.home.file."${config.xdg.configHome}/vicinae/home-manager.json"
          )
        ];
      message = "Vicinae must restart for the override file at its final target.";
    }
  ];
  nmt.script = ''
    assertFileContent "home-files/layers/my % settings.json" ${../read-only-layer.json}
    assertPathNotExists "home-files/.config/vicinae/settings.json"
    assertFileContains "home-path/etc/profile.d/hm-session-vars.sh" 'export VICINAE_OVERRIDES="${config.home.homeDirectory}/layers/my % settings.json"'
    assertFileContains "home-files/.config/systemd/user/vicinae.service" 'Environment="VICINAE_OVERRIDES=${config.home.homeDirectory}/layers/my %% settings.json"'
  '';
}
