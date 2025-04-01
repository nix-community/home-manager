{ config, lib, pkgs, ... }:
let

  cfg = config.programs.ruff;

  settingsFormat = pkgs.formats.toml { };

in {
  meta.maintainers = [ lib.hm.maintainers.GaetanLepage ];

  options.programs.ruff = {
    enable = lib.mkEnableOption
      "ruff, an extremely fast Python linter and code formatter, written in Rust";

    package = lib.mkPackageOption pkgs "ruff" { nullable = true; };

    settings = lib.mkOption {
      type = settingsFormat.type;
      example = lib.literalExpression ''
        {
          line-length = 100;
          per-file-ignores = { "__init__.py" = [ "F401" ]; };
          lint = {
            select = [ "E4" "E7" "E9" "F" ];
            ignore = [ ];
          };
        }
      '';
      description = ''
        Ruff configuration.
        For available settings see <https://docs.astral.sh/ruff/settings>.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."ruff/ruff.toml".source =
      settingsFormat.generate "ruff.toml" cfg.settings;
  };
}
