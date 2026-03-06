{
  lib,
  config,
  pkgs,
  ...
}:
let
  tomlFormat = pkgs.formats.toml { };
  cfg = config.programs.cargo;
in
{
  meta.maintainers = [ lib.maintainers.friedrichaltheide ];

  options = {
    programs = {
      cargo = {
        enable = lib.mkEnableOption "management of cargo config";

        package = lib.mkPackageOption pkgs "cargo" { nullable = true; };

        cargoHome = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          apply = p: if p != null then lib.removePrefix "${config.home.homeDirectory}/" p else p;
          default = null;
          example = lib.literalExpression "\${config.xdg.dataHome}/cargo";
          description = "Directory to store cargo configuration & state. Setting this also sets $CARGO_HOME.";
        };

        settings = lib.mkOption {
          inherit (tomlFormat) type;
          default = { };
          description = ''
            Available configuration options for the $CARGO_HOME/config see:
            https://doc.rust-lang.org/cargo/reference/config.html
          '';
        };
      };
    };
  };

  config =
    let
      cargoHome = if cfg.cargoHome != null then cfg.cargoHome else ".cargo";
    in
    lib.mkIf cfg.enable {
      home = {
        packages = lib.mkIf (cfg.package != null) [ cfg.package ];

        sessionVariables = lib.mkIf (cfg.cargoHome != null) {
          CARGO_HOME = "${config.home.homeDirectory}/${cfg.cargoHome}";
        };

        file = {
          "${cargoHome}/config.toml" = {
            source = tomlFormat.generate "config.toml" cfg.settings;
          };
        };
      };
    };
}
