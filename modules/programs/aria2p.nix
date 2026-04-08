{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.aria2p;

  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = [ lib.maintainers.oneorseveralcats ];

  options.programs.aria2p = {
    enable = lib.mkEnableOption "aria2p a terminal client for aria2c.";

    package = lib.mkPackageOption pkgs [ "python3Packages" "aria2p" ] { nullable = true; };

    settings = lib.mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = {
        key_bindings = {
          AUTOCLEAR = "c";
          FILTER = [
            "F4"
            "\\"
          ];
        };
        colors = {
          UI = "WHITE BOLD DEFAULT";
          FOCUSED_HEADER = "BLACK NORMAL CYAN";
          METADATA = "WHITE UNDERLINE DEFAULT";
        };
      };
      description = ''
        Keybinding and color settings for aria2p.
        Running aria2p generates a default configuration with
        all the options at {file}`~/.config/aria2p/config.toml`
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."aria2p/config.toml" = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "settings" cfg.settings;
    };
  };
}
