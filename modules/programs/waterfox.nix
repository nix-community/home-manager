{ lib, config, ... }:
let
  modulePath = [
    "programs"
    "waterfox"
  ];

  cfg = config.programs.waterfox;

  mkFirefoxModule = import ./firefox/mkFirefoxModule.nix;
in
{
  meta.maintainers = [ lib.maintainers.maximsmol ];

  imports = [
    (mkFirefoxModule {
      inherit modulePath;
      name = "Waterfox";
      description = "Waterfox, a privacy focused, performance oriented browser based on Firefox.";
      wrappedPackageName = "waterfox-bin";
      unwrappedPackageName = "waterfox-bin-unwrapped";

      platforms.linux = {
        configPath = ".waterfox";
      };
      platforms.darwin = {
        appName = "Waterfox";
        configPath = "Library/Application Support/Waterfox";
      };
    })
  ];

  config = lib.mkIf cfg.enable {
    mozilla.firefoxNativeMessagingHosts =
      cfg.nativeMessagingHosts
      # package configured native messaging hosts (entire browser actually)
      ++ (lib.optional (cfg.finalPackage != null) cfg.finalPackage);
  };
}
