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

        settings = lib.mkOption {
          inherit (tomlFormat) type;
          default = { };
          description = ''
            Available configuration options for the .cargo/config see:
            https://doc.rust-lang.org/cargo/reference/config.html
          '';
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = lib.mkIf (cfg.package != null) [ cfg.package ];

      file = {
        ".cargo/config.toml" = {
          source = tomlFormat.generate "config.toml" cfg.settings;
        };
      };
    };
  };
}
