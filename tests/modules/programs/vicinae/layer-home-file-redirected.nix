{
  config,
  lib,
  realPkgs,
  ...
}:
{
  home.file."${config.xdg.configHome}/vicinae/home-manager.json" = {
    target = lib.mkForce "layers/my % $hm_layer_probe \"quoted\" back\\$hm_layer_probe `printf altered` settings.json";
    enable = true;
  };
  programs.vicinae = {
    enable = true;
    enableMutableConfig = true;
    settings.font.normal.size = 12;
    systemd.enable = true;
    enableFirefoxIntegration = false;
  };
  assertions = [
    {
      assertion =
        config.home.sessionVariables.VICINAE_OVERRIDES
        == ''/home/hm-user/layers/my % \$hm_layer_probe \"quoted\" back\\\$hm_layer_probe \`printf altered\` settings.json'';
      message = "Vicinae's session selector must follow the final home.file target.";
    }
    {
      assertion =
        config.systemd.user.services.vicinae.Service.Environment == [
          ''"VICINAE_OVERRIDES=/home/hm-user/layers/my %% $hm_layer_probe \"quoted\" back\\$hm_layer_probe `printf altered` settings.json"''
        ];
      message = "Vicinae's service selector must follow the final home.file target.";
    }
  ];
  nmt.script = ''
    assertFileContent 'home-files/layers/my % $hm_layer_probe "quoted" back\$hm_layer_probe `printf altered` settings.json' ${./read-only-layer.json}
    assertPathNotExists "home-files/.config/vicinae/home-manager.json"
    assertPathNotExists "home-files/.config/vicinae/settings.json"
    assertFileContains "home-files/.config/systemd/user/vicinae.service" 'Environment="VICINAE_OVERRIDES=/home/hm-user/layers/my %% $hm_layer_probe \"quoted\" back\\$hm_layer_probe `printf altered` settings.json"'
    ${lib.getExe realPkgs.bash} -c '
      . "$1"
      test "$VICINAE_OVERRIDES" = "$2"
    ' -- "$TESTED/home-path/etc/profile.d/hm-session-vars.sh" \
      '/home/hm-user/layers/my % $hm_layer_probe "quoted" back\$hm_layer_probe `printf altered` settings.json' \
      || fail "Vicinae's session selector must preserve the literal filename"
  '';
}
