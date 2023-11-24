{ config, lib, pkgs, ... }:

{
  imports = [ ./setup-firefox-mock-overlay.nix ];

  config = lib.mkIf config.test.enableBig {
    home.stateVersion = "23.05";

    programs.firefox = {
      enable = true;
      policies = { BlockAboutConfig = true; };
    };

    nmt.script = ''
      jq=${lib.getExe pkgs.jq}
      config_file="${config.programs.firefox.finalPackage}/lib/firefox/distribution/policies.json"

      assertFileExists "$config_file"
      blockAboutConfig_actual_value="$($jq ".policies.BlockAboutConfig" $config_file)"

      if [[ $blockAboutConfig_actual_value != "true" ]]; then
        fail "Expected '$config_file' to set 'policies.BlockAboutConfig' to true"
      fi
    '';
  };
}
