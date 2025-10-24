{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.targets.darwin;
in
{
  options.targets.darwin.linkApps = {
    enable = lib.mkEnableOption "linking macOS applications to the user environment" // {
      default = true;
    };

    directory = lib.mkOption {
      type = lib.types.str;
      default = "Applications/Home Manager Apps";
      description = "Path to link apps relative to the home directory.";
    };
  };

  config = lib.mkIf (pkgs.stdenv.hostPlatform.isDarwin && cfg.linkApps.enable) {
    # Install MacOS applications to the user environment.
    home.file =
      let
        packagesWithApps = builtins.filter (
          pkg: builtins.pathExists "${pkg}/Applications"
        ) config.home.packages;
        apps = lib.flatten (
          map (
            pkg:
            map (
              { name, ... }:
              {
                name = "${cfg.linkApps.directory}/${name}/Contents";
                value = {
                  source = "${pkg}/Applications/${name}/Contents";
                };
              }
            ) (lib.attrsToList (builtins.readDir "${pkg}/Applications"))
          ) packagesWithApps
        );
      in
      (builtins.listToAttrs apps);
  };
}
