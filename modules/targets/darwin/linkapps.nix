{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.targets.darwin.linkApps;
in
{
  options.targets.darwin.linkApps = {
    enable = lib.mkEnableOption "linking macOS applications to the user environment" // {
      default = pkgs.stdenv.hostPlatform.isDarwin;
    };

    directory = lib.mkOption {
      type = lib.types.str;
      default = "Applications/Home Manager Apps";
      description = "Path to link apps relative to the home directory.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "targets.darwin.linkApps" pkgs lib.platforms.darwin)
    ];

    # Install MacOS applications to the user environment.
    home.file.${cfg.directory}.source =
      let
        apps = pkgs.buildEnv {
          name = "home-manager-applications";
          paths = config.home.packages;
          pathsToLink = "/Applications";
        };
      in
      "${apps}/Applications";
  };
}
