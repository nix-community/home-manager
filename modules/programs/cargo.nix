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

        home = lib.mkOption {
          type = lib.types.str;
          default = ".cargo";
          description = ''
            The home directory of cargo. This is where the configuration,
            the registry and the git dependencies are stored by cargo.
          '';
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

  config = lib.mkIf cfg.enable {
    home = {
      packages = lib.mkIf (cfg.package != null) [ cfg.package ];

      sessionVariables = lib.mkIf (cfg.home != ".cargo") {
        CARGO_HOME = "${config.home.homeDirectory}/${cfg.home}";
      };

      file = {
        "${cfg.home}/config.toml" = {
          source = tomlFormat.generate "config.toml" cfg.settings;
        };
      };
    };
  };
}
