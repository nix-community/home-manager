{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.giff;

  tomlFormat = pkgs.formats.toml { };

  inherit (lib)
    mkOption
    ;
in
{
  meta.maintainers = with lib.maintainers; [ matthiasbeyer ];

  options.programs.giff = {
    enable = lib.mkEnableOption "giff, a terminal-based Git diff viewer with interactive rebase capabilities";

    package = lib.mkPackageOption pkgs "giff" { nullable = true; };

    settings = mkOption {
      type = tomlFormat.type;

      default = { };

      example = {
        theme = "dark";

        themes.custom = {
          base = "dark";
          accent = "#89b4fa";
          fg_added = "#a6e3a1";
          fg_removed = "#f38ba8";
        };
      };

      description = ''
        Options to configure giff.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."giff/config.toml" = lib.mkIf (cfg.options != { }) {
      source = tomlFormat.generate "giff-config" cfg.options;
    };
  };
}
