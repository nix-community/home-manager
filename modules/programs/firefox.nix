{ lib, config, ... }:
let
  inherit (lib) mkRemovedOptionModule;

  cfg = config.programs.firefox;

  modulePath = [
    "programs"
    "firefox"
  ];

  moduleName = lib.concatStringsSep "." modulePath;

  mkFirefoxModule = import ./firefox/mkFirefoxModule.nix;
in
{
  meta.maintainers = [
    lib.maintainers.rycee
    lib.hm.maintainers.bricked
    lib.hm.maintainers.HPsaucii
  ];

  imports = [
    (mkFirefoxModule {
      inherit modulePath;
      name = "Firefox";
      wrappedPackageName = "firefox";
      unwrappedPackageName = "firefox-unwrapped";
      visible = true;

      platforms.linux = {
        configPath = ".mozilla/firefox";
      };
      platforms.darwin = {
        configPath = "Library/Application Support/Firefox";
      };
    })

    (mkRemovedOptionModule (modulePath ++ [ "extensions" ]) ''
      Extensions are now managed per-profile. That is, change from

        ${moduleName}.extensions = [ foo bar ];

      to

        ${moduleName}.profiles.myprofile.extensions.packages = [ foo bar ];'')
    (mkRemovedOptionModule (
      modulePath ++ [ "enableAdobeFlash" ]
    ) "Support for this option has been removed.")
    (mkRemovedOptionModule (
      modulePath ++ [ "enableGoogleTalk" ]
    ) "Support for this option has been removed.")
    (mkRemovedOptionModule (
      modulePath ++ [ "enableIcedTea" ]
    ) "Support for this option has been removed.")
  ];

  config = lib.mkIf cfg.enable {
    mozilla.firefoxNativeMessagingHosts =
      cfg.nativeMessagingHosts
      # package configured native messaging hosts (entire browser actually)
      ++ (lib.optional (cfg.finalPackage != null) cfg.finalPackage);
  };
}
