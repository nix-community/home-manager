{
  config,
  lib,
  pkgs,
  ...
}:
let
  thunderbirdPackage = config.lib.test.mkStubPackage {
    name = "thunderbird";
    version = "140.0.2";
    extraAttrs = {
      override =
        f:
        let
          overrides = f {
            extraPolicies = {
              DisableAppUpdate = true;
            };
          };
          policiesJson = pkgs.writeText "policies.json" (
            builtins.toJSON {
              policies = overrides.extraPolicies;
            }
          );
        in
        (pkgs.runCommandLocal "thunderbird-with-policies" { } ''
          mkdir -p "$out/lib/thunderbird/distribution"
          cp ${policiesJson} "$out/lib/thunderbird/distribution/policies.json"
        '')
        // {
          inherit (overrides) extraPolicies;
        };
    };
  };

  expectedPolicies = {
    policies = {
      DisableAppUpdate = true;
      DisableTelemetry = true;
      ExtensionSettings = {
        "langpack-de@thunderbird.mozilla.org" = {
          install_url = "https://releases.mozilla.org/pub/thunderbird/releases/140.0.2/linux-x86_64/xpi/de.xpi";
          installation_mode = "normal_installed";
        };
        "langpack-en-GB@thunderbird.mozilla.org" = {
          install_url = "https://releases.mozilla.org/pub/thunderbird/releases/140.0.2/linux-x86_64/xpi/en-GB.xpi";
          installation_mode = "normal_installed";
        };
      };
      RequestedLocales = "de,en-GB";
    };
  };
in
{
  programs.thunderbird = {
    enable = true;
    package = thunderbirdPackage;

    languagePacks = [
      "de"
      "en-GB"
    ];

    policies = {
      DisableTelemetry = true;
    };
  };

  nmt.script = ''
    assertFileExists ${config.programs.thunderbird.finalPackage}/lib/thunderbird/distribution/policies.json
    assertFileContent \
      ${config.programs.thunderbird.finalPackage}/lib/thunderbird/distribution/policies.json \
      ${pkgs.writeText "thunderbird-expected-policies.json" (
        lib.generators.toJSON { } expectedPolicies
      )}
  '';
}
