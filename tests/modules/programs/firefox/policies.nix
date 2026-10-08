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

  uBlockStubPkg = config.lib.test.mkStubPackage {
    name = "ublock-origin-dummy";
    extraAttrs.addonId = "uBlock0@raymondhill.net";
  };

  privacyBadgerStubPkg = config.lib.test.mkStubPackage {
    name = "privacy-badger-dummy";
    extraAttrs.addonId = "jid1-MnnxcxisBPnSXQ@jetpack";
  };
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
      globalExtensions = [
        uBlockStubPkg
        {
          package = privacyBadgerStubPkg;
          settings = {
            default_area = "menupanel";
            private_browsing = true;
          };
        }
      ];
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

          ublock_installation_mode="$($jq --arg extid "${uBlockStubPkg.addonId}" ".policies.ExtensionSettings[\$extid].installation_mode" ${config_file})"

          if [[ $ublock_installation_mode != "\"force_installed\"" ]]; then
            fail "Expected '${config_file}' to force-install ${uBlockStubPkg.addonId}"
          fi

          ublock_install_url="$($jq --arg extid "${uBlockStubPkg.addonId}" ".policies.ExtensionSettings[\$extid].install_url" ${config_file})"
          expected_ublock_install_url="\"file://${uBlockStubPkg}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/${uBlockStubPkg.addonId}.xpi\""

          if [[ $ublock_install_url != "$expected_ublock_install_url" ]]; then
            fail "Expected '${config_file}' to set install_url for ${uBlockStubPkg.addonId}"
          fi

          privacy_badger_private_browsing="$($jq --arg extid "${privacyBadgerStubPkg.addonId}" ".policies.ExtensionSettings[\$extid].private_browsing" ${config_file})"

          if [[ $privacy_badger_private_browsing != "true" ]]; then
            fail "Expected '${config_file}' to preserve custom settings for ${privacyBadgerStubPkg.addonId}"
          fi

          privacy_badger_default_area="$($jq --arg extid "${privacyBadgerStubPkg.addonId}" ".policies.ExtensionSettings[\$extid].default_area" ${config_file})"

          if [[ $privacy_badger_default_area != "\"menupanel\"" ]]; then
            fail "Expected '${config_file}' to preserve default_area for ${privacyBadgerStubPkg.addonId}"
          fi
        '';
    }
  );
}
