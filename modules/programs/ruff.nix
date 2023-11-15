{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.ruff;

  settingsFormat = pkgs.formats.toml { };

in {
  meta.maintainers = [ hm.maintainers.GaetanLepage ];

  options.programs.ruff = {
    enable = mkEnableOption
      "ruff, an extremely fast Python linter and code formatter, written in Rust";

    package = mkPackageOption pkgs "ruff" { };

    settings = mkOption {
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

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."ruff/ruff.toml".source =
      settingsFormat.generate "ruff.toml" cfg.settings;
  };
}
