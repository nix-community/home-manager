{ config, lib, pkgs, ... }:

let
  inherit (lib) literalExpression mkOption mkEnableOption mkIf types;
  cfg = config.programs.clock-rs;
  tomlFormat = pkgs.formats.toml { };
  configDir = if pkgs.stdenv.isDarwin then
    "Library/Application Support"
  else
    config.xdg.configHome;
in {
  meta.maintainers = with lib.maintainers; [ oughie ];

  config = mkIf cfg.enable {
    home.packages = [ pkgs.clock-rs ];

    home.file."${configDir}/clock-rs/conf.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "clock-rs-config" cfg.settings;
    };
  };

  options.programs.clock-rs = {
    enable = mkEnableOption "clock-rs";

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      description = "The configuration file to be used for clock-rs";
      example = literalExpression ''
        general = {
          color = "magenta";
          interval = 250;
          blink = true;
          bold = true;
        };

        position = {
          horizontal = "start";
          vertical = "end";
        };

        date = {
          fmt = "%A, %B %d, %Y";
          use_12h = true;
          utc = true;
          hide_seconds = true;
        };
      '';
    };

    general = {
      color = mkOption {
        type = types.str;
        default = "magenta";
        example = "magenta";
        description = "The color of the clock.";
      };

      interval = mkOption {
        type = types.int;
        default = 200;
        example = 250;
        description = "The polling interval in milliseconds.";
      };

      blink = mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = "Whether the colon should blink.";
      };

      bold = mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = "Whether to use bold text.";
      };
    };

    position = {
      horizontal = mkOption {
        type = types.str;
        default = "center";
        example = "start";
        description = "The position along the horizontal axis.";
      };
      vertical = mkOption {
        type = types.str;
        default = "center";
        example = "start";
        description = "The position along the vertical axis.";
      };
    };

    date = {
      fmt = mkOption {
        type = types.str;
        default = "%d-%m-%Y";
        example = "%A, %B %d, %Y";
        description = "The date format.";
      };

      use_12h = mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = "Use the 12h format.";
      };

      utc = mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = "Use UTC time.";
      };

      hide_seconds = mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = "Do not show seconds.";
      };
    };
  };
}
