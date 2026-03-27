{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    ;

  cfg = config.programs.macchina;
  tomlFormat = pkgs.formats.toml { };

  themes = import ./theme.nix { inherit lib; };
  settings = import ./settings.nix { inherit lib; };

  # Strip null values recursively before handing off to the TOML generator.
  stripNulls = lib.filterAttrsRecursive (_: v: v != null);
in
{
  meta.maintainers = [ lib.maintainers.philocalyst ];

  options.programs.macchina = {
    enable = lib.mkEnableOption "macchina system information fetcher";

    package = lib.mkPackageOption pkgs "macchina" { nullable = true; };

    inherit (themes) themes;
    inherit (settings) settings;
  };

  config = mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile =
      let
        settingsAttrs = stripNulls {
          inherit (cfg.settings)
            interface
            long_uptime
            long_shell
            long_kernel
            current_shell
            physical_cores
            disks
            disk_space_percentage
            memory_percentage
            theme
            show
            ;
        };

        themeFiles = lib.mapAttrs' (
          name: theme:
          lib.nameValuePair "macchina/themes/${name}.toml" {
            source = tomlFormat.generate "macchina-theme-${name}" (stripNulls theme);
          }
        ) cfg.themes;
      in
      lib.optionalAttrs (settingsAttrs != { }) {
        "macchina/macchina.toml".source = tomlFormat.generate "macchina.toml" settingsAttrs;
      }
      // themeFiles;
  };
}
