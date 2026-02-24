{ lib, config, ... }:
let
  modulePath = [
    "programs"
    "floorp"
  ];

  cfg = config.programs.floorp;

  mkFirefoxModule = import ./firefox/mkFirefoxModule.nix;
in
{
  meta.maintainers = [ lib.maintainers.bricked ];

  imports = [
    (mkFirefoxModule {
      inherit modulePath;
      name = "Floorp";
      wrappedPackageName = "floorp-bin";
      unwrappedPackageName = "floorp-bin-unwrapped";

      platforms.linux = {
        configPath = ".floorp";
      };
      platforms.darwin = {
        configPath = "Library/Application Support/Floorp";
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
