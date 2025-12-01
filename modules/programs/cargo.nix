{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption;

  tomlFormat = pkgs.formats.toml { };

  cfg = config.programs.cargo;
in
{
  meta.maintainers = [ lib.maintainers.friedrichaltheide ];

  options = {
    programs = {
      cargo = {
        enable = mkEnableOption "management of cargo config";

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
      file = {
        ".cargo/config.toml" = {
          source = tomlFormat.generate "config.toml" cfg.settings;
        };
      };
    };
  };
}
