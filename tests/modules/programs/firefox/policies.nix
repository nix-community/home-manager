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
    lib.setAttrByPath modulePath {
      enable = true;
      configPath = lib.mkIf pkgs.stdenv.hostPlatform.isLinux ".mozilla/firefox";
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
              "${cfg.finalPackage}/lib/${cfg.finalPackage.unwrapped.libName or cfg.wrappedPackageName}";
          config_file = "${libDir}/distribution/policies.json";
          config_file_browser = "${libDir}/browser/distribution/policies.json";
        in
        ''
          jq=${lib.getExe pkgs.jq}
          if [[ -f "${config_file}" ]]; then
            config_file="${config_file}"
          elif [[ -f "${config_file_browser}" ]]; then
            config_file="${config_file_browser}"
          else
            fail "Expected ${libDir}/distribution/policies.json to exist but it was not found."
          fi

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
