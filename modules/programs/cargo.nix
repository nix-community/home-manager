{
  lib,
  config,
  pkgs,
  ...
}:
let
  tomlFormat = pkgs.formats.toml { };

  defaultCargoHome = ".cargo";

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
          default = null;
          example = ".cargo";
          description = ''
            The location of the cargo home directory, from `~`, which caches downloads and holds the Cargo configuration file.
            If not null, sets the `CARGO_HOME` environment variable. and places the config file in `$CARGO_HOME/config.toml`.
            See: https://doc.rust-lang.org/cargo/guide/cargo-home.html
          '';
        };

        settings = lib.mkOption {
          inherit (tomlFormat) type;
          default = { };
          description = ''
            Available configuration options for the cargo configuration file, see:
            https://doc.rust-lang.org/cargo/reference/config.html
          '';
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = lib.mkIf (cfg.package != null) [ cfg.package ];

      file =
        let
          cargoHomePath = if cfg.cargoHome != null then cfg.cargoHome else defaultCargoHome;
        in
        {
          "${cargoHomePath}/config.toml" = {
            source = tomlFormat.generate "config.toml" cfg.settings;
          };
        };
      sessionVariables = lib.mkIf (cfg.cargoHome != null) {
        CARGO_HOME = "${config.home.homeDirectory}/${cfg.cargoHome}";
      };
    };
  };
}
