{
  expectedDarwinPath,
  packageIsNull ? false,
  stateVersion,
}:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.firefox;

  expectedConfigPath =
    if pkgs.stdenv.hostPlatform.isDarwin then expectedDarwinPath else ".config/mozilla/firefox";

  expectedAppDataDir =
    if
      pkgs.stdenv.hostPlatform.isDarwin && !packageIsNull && lib.versionAtLeast stateVersion "26.11"
    then
      "${config.home.homeDirectory}/${expectedDarwinPath}"
    else
      null;

  firefoxPackage = lib.makeOverridable (
    {
      cfg ? { },
      extraPolicies ? { },
      pkcs11Modules ? [ ],
      appDataDir ? null,
    }:
    builtins.deepSeq
      [
        cfg
        extraPolicies
        pkcs11Modules
      ]
      (
        config.lib.test.mkStubPackage {
          name = "firefox-config-path-darwin-default-test-stub";
          extraAttrs = {
            browserName = "firefox";
            inherit appDataDir;
            meta.mainProgram = "firefox";
          };
        }
      )
  ) { };
in
{
  config = lib.mkIf config.test.enableBig {
    home.stateVersion = stateVersion;

    programs.firefox = {
      enable = true;
      package = if packageIsNull then null else firefoxPackage;
      profiles.test.settings."general.smoothScroll" = false;
    };

    assertions = [
      {
        assertion = cfg.configPath == expectedConfigPath;
        message = "Firefox configPath has an unexpected default";
      }
      {
        assertion = cfg.finalPackage == null || cfg.finalPackage.appDataDir == expectedAppDataDir;
        message = "Firefox wrapper received an unexpected appDataDir";
      }
    ];

    mozilla.firefoxNativeMessagingHosts = lib.mkForce [ ];
  };
}
