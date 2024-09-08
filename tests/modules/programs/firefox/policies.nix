modulePath:
{ config, lib, pkgs, ... }:

with lib;

let

  cfg = getAttrFromPath modulePath config;

  firefoxMockOverlay = import ./setup-firefox-mock-overlay.nix modulePath;

in {
  imports = [ firefoxMockOverlay ];

  config = mkIf config.test.enableBig ({
    home.stateVersion = "23.05";
  } // setAttrByPath modulePath {
    enable = true;
    policies = { BlockAboutConfig = true; };
    package = pkgs.${cfg.wrappedPackageName}.override {
      extraPolicies = { DownloadDirectory = "/foo"; };
    };
  }) // {
    nmt.script = ''
      jq=${lib.getExe pkgs.jq}
      config_file="${cfg.finalPackage}/lib/${cfg.wrappedPackageName}/distribution/policies.json"

      assertFileExists "$config_file"

      blockAboutConfig_actual_value="$($jq ".policies.BlockAboutConfig" $config_file)"

      if [[ $blockAboutConfig_actual_value != "true" ]]; then
        fail "Expected '$config_file' to set 'policies.BlockAboutConfig' to true"
      fi

      downloadDirectory_actual_value="$($jq ".policies.DownloadDirectory" $config_file)"

      if [[ $downloadDirectory_actual_value != "\"/foo\"" ]]; then
        fail "Expected '$config_file' to set 'policies.DownloadDirectory' to \"/foo\""
      fi
    '';
  };
}
