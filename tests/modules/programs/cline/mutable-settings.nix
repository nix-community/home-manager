{ config, ... }:
{
  programs.cline = {
    enable = true;
    package = null;
    mutableSettings = true;
    configDir = "${config.home.homeDirectory}/custom-cline";
    providers.version = 1;
    models.version = 1;
  };

  assertions = [
    {
      assertion = (config.home.activation.clineSettings.after or [ ]) == [ "linkGeneration" ];
      message = "Mutable Cline settings must activate after linkGeneration.";
    }
  ];

  nmt.script = ''
    assertPathNotExists home-files/custom-cline/data/settings/models.json
    assertPathNotExists home-files/custom-cline/data/settings/providers.json
    assertFileContains activate '${config.programs.cline.configDir}/data/settings/models.json'
    assertFileContains activate '${config.programs.cline.configDir}/data/settings/providers.json'

    providers="$(grep -o '/nix/store/[^ ]*-cline-providers.json' "$TESTED/activate")" \
      || fail "Cline providers settings input is missing from activation"
    assertFileContains "$providers" '"version": 1'
  '';
}
