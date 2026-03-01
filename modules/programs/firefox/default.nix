{
  lib,
  config,
  options,
  pkgs,
  ...
}:
let
  inherit (lib) mkRemovedOptionModule;

  cfg = config.programs.firefox;

  linuxConfigPath =
    if lib.versionAtLeast config.home.stateVersion "26.11" then
      "${config.xdg.configHome}/mozilla/firefox"
    else
      ".mozilla/firefox";

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
        configPath = linuxConfigPath;
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
    warnings =
      lib.optionals
        (
          pkgs.stdenv.hostPlatform.isLinux
          && !lib.versionAtLeast config.home.stateVersion "26.11"
          && options.programs.firefox.configPath.highestPrio >= 1500
        )
        [
          ''
            The default value of `programs.firefox.configPath` will change in a future release.
            You are currently using the legacy default (`.mozilla/firefox`) because `home.stateVersion` is less than "26.11".

            Please set `programs.firefox.configPath` explicitly to lock in your choice:
              programs.firefox.configPath = ".mozilla/firefox";
              # New default in 26.11+
              programs.firefox.configPath = "''${config.xdg.configHome}/mozilla/firefox";

            To migrate to the XDG path, move `~/.mozilla/firefox` to `~/.config/mozilla/firefox`.
            Firefox keeps using the legacy path if `~/.mozilla/firefox` still exists.
            Migrating profiles can break existing setups, so make a backup before moving.
          ''
        ];

    mozilla.firefoxNativeMessagingHosts =
      cfg.nativeMessagingHosts
      # package configured native messaging hosts (entire browser actually)
      ++ (lib.optional (cfg.finalPackage != null) cfg.finalPackage);
  };
}
