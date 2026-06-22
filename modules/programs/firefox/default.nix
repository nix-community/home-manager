{
  lib,
  config,
  pkgs,
  options,
  ...
}:
let
  inherit (lib) mkRemovedOptionModule;

  cfg = config.programs.firefox;

  linuxConfigHome = lib.removePrefix "${config.home.homeDirectory}/" config.xdg.configHome;

  linuxConfigPathStateVersion = lib.hm.deprecations.mkStateVersionOptionDefault {
    inherit (config.home) stateVersion;
    since = "26.05";
    inherit config;
    inherit options;
    deferWarningToConfig = true;
    optionPath = [
      "programs"
      "firefox"
      "configPath"
    ];
    legacy = {
      value = ".mozilla/firefox";
    };
    current = {
      value = "${linuxConfigHome}/mozilla/firefox";
      text = ''"''${config.xdg.configHome}/mozilla/firefox"'';
    };
    shouldWarn =
      { optionUsesDefaultPriority, ... }: optionUsesDefaultPriority && !pkgs.stdenv.hostPlatform.isDarwin;
    extraWarning = ''
      To migrate to the XDG path, move `~/.mozilla/firefox` to
      `$XDG_CONFIG_HOME/mozilla/firefox` and remove the old directory.
      Native messaging hosts are not moved by this option change.
    '';
  };

  modulePath = [
    "programs"
    "firefox"
  ];

  moduleName = lib.concatStringsSep "." modulePath;

  mkFirefoxModule = import ./mkFirefoxModule.nix;
in
{
  meta.maintainers = with lib.maintainers; [
    bricked
    rycee
    lib.hm.maintainers.HPsaucii
  ];

  imports = [
    (mkFirefoxModule {
      inherit modulePath;
      name = "Firefox";
      wrappedPackageName = "firefox";
      unwrappedPackageName = "firefox-unwrapped";

      platforms.linux = {
        configPath = linuxConfigPathStateVersion.effectiveDefault;
      };
      platforms.darwin = {
        configPath = "Library/Application Support/Firefox";
        defaultsId = "org.mozilla.firefox.plist";
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
    warnings = lib.optional linuxConfigPathStateVersion.shouldWarn linuxConfigPathStateVersion.warning;

    mozilla.firefoxNativeMessagingHosts =
      cfg.nativeMessagingHosts
      # package configured native messaging hosts (entire browser actually)
      ++ (lib.optional (cfg.finalPackage != null) cfg.finalPackage);
  };
}
