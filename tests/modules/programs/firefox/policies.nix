modulePath:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = lib.getAttrFromPath modulePath config;

  firefoxMockOverlay = import ./setup-firefox-mock-overlay.nix modulePath;

  darwinPath = "Applications/${cfg.darwinAppName}.app/Contents/Resources";
in
{
  imports = [ firefoxMockOverlay ];

  config = lib.mkIf config.test.enableBig (
    {
      home.stateVersion = "23.05";
    }
    // lib.setAttrByPath modulePath {
      enable = true;
      policies = {
        BlockAboutConfig = true;
      };
      package = pkgs.${cfg.wrappedPackageName}.override {
        extraPolicies = {
          DownloadDirectory = "/foo";
        };
      };
    }
    // {
      nmt.script =
        let
          libDir =
            if pkgs.stdenv.hostPlatform.isDarwin then
              "${cfg.finalPackage}/${darwinPath}"
            else
              "${cfg.finalPackage}/lib/${cfg.wrappedPackageName}";
          config_file = "${libDir}/distribution/policies.json";
        in
        ''
          jq=${lib.getExe pkgs.jq}

          assertFileExists "${config_file}"

          blockAboutConfig_actual_value="$($jq ".policies.BlockAboutConfig" ${config_file})"

          if [[ $blockAboutConfig_actual_value != "true" ]]; then
            fail "Expected '${config_file}' to set 'policies.BlockAboutConfig' to true"
          fi

          downloadDirectory_actual_value="$($jq ".policies.DownloadDirectory" ${config_file})"

          if [[ $downloadDirectory_actual_value != "\"/foo\"" ]]; then
            fail "Expected '${config_file}' to set 'policies.DownloadDirectory' to \"/foo\""
          fi
        '';
    }
  );
}
