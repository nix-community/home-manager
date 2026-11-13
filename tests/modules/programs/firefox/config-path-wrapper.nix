{
  absolute ? false,
  configPath,
  supportsAppDataDir ? true,
}:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.firefox;

  effectiveConfigPath = if absolute then "${config.home.homeDirectory}/${configPath}" else configPath;

  expectedAppDataDir = "${config.home.homeDirectory}/${configPath}";

  mkPackage =
    appDataDir:
    config.lib.test.mkStubPackage {
      name = "firefox-config-path-test-stub";
      buildScript = ''
        mkdir -p "$out/lib/mozilla/native-messaging-hosts"
      '';
      extraAttrs = {
        browserName = "firefox";
        inherit appDataDir;
        meta.mainProgram = "firefox";
      };
    };

  packageWithAppDataDir = lib.makeOverridable (
    {
      cfg ? { },
      extraPolicies ? { },
      pkcs11Modules ? [ ],
      appDataDir ? null,
    }:
    builtins.deepSeq [
      cfg
      extraPolicies
      pkcs11Modules
    ] (mkPackage appDataDir)
  ) { };

  packageWithoutAppDataDir = lib.makeOverridable (
    {
      cfg ? { },
      extraPolicies ? { },
      pkcs11Modules ? [ ],
    }:
    builtins.deepSeq [
      cfg
      extraPolicies
      pkcs11Modules
    ] (mkPackage null)
  ) { };
in
{
  config = lib.mkIf config.test.enableBig {
    home = {
      homeDirectory = lib.mkForce (
        if pkgs.stdenv.hostPlatform.isDarwin then "/Users/hm-user" else "/home/hm-user"
      );
      stateVersion = "26.05";
    };

    programs.firefox = {
      enable = true;
      configPath = effectiveConfigPath;
      package = if supportsAppDataDir then packageWithAppDataDir else packageWithoutAppDataDir;
      profiles.test.settings."general.smoothScroll" = false;
    };

    assertions = [
      {
        assertion =
          cfg.finalPackage.appDataDir == (if supportsAppDataDir then expectedAppDataDir else null);
        message = "Firefox wrapper received an unexpected appDataDir";
      }
    ];

    mozilla.firefoxNativeMessagingHosts = lib.mkForce [ ];

    nmt.script = ''
      assertFileExists "home-files/${configPath}/profiles.ini"
    '';
  };
}
