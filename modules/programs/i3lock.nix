{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.programs.i3lock;

  escape = escapeShellArg;

  matchesColor = color: (builtins.match "^[a-fA-F0-9]{8}$" color) != null;

  colorType = types.nullOr (types.addCheck types.str matchesColor);

  lockCmd = concatStringsSep " " (filter (value: value != "") [
    cfg.cmd

    # general
    (optionalString (cfg.background.color != null)
      "--color=${cfg.background.color}")
    (optionalString (cfg.background.image != null)
      "--image=${cfg.background.image}")
    (optionalString (cfg.background.blur != null)
      "--blur=${toString cfg.background.blur}")
    (optionalString cfg.beep "--beep")
    (optionalString cfg.indicator "--indicator")
    (optionalString (cfg.pointer != null) "--pointer=${cfg.pointer}")

    # clock
    (optionalString cfg.clock.enable "--clock")
    (optionalString cfg.clock.enable "--timestr=${escape cfg.clock.timeFormat}")
    (optionalString cfg.clock.enable "--datestr=${escape cfg.clock.dateFormat}")

    # text
    (optionalString (cfg.text.verify != null)
      "--veriftext=${escape cfg.text.verify}")
    (optionalString (cfg.text.wrong != null)
      "--wrongtext=${escape cfg.text.wrong}")
    (optionalString (cfg.text.noInput != null)
      "--noinputtext=${escape cfg.text.noInput}")
    (optionalString (cfg.text.lock != null)
      "--locktext=${escape cfg.text.lock}")
    (optionalString (cfg.text.lockFailed != null)
      "--lockfailedtext=${escape cfg.text.lockFailed}")
    (optionalString (cfg.text.greeter != null)
      "--greetertext=${escape cfg.text.greeter}")

    # text font
    (optionalString (cfg.text.font.time != null)
      "--time-font=${escape cfg.text.font.time}")
    (optionalString (cfg.text.font.date != null)
      "--date-font=${escape cfg.text.font.date}")
    (optionalString (cfg.text.font.layout != null)
      "--layout-font=${escape cfg.text.font.layout}")
    (optionalString (cfg.text.font.verify != null)
      "--verif-font=${escape cfg.text.font.verify}")
    (optionalString (cfg.text.font.wrong != null)
      "--wrong-font=${escape cfg.text.font.wrong}")
    (optionalString (cfg.text.font.greeter != null)
      "--greeter-font=${escape cfg.text.font.greeter}")

    # text size
    (optionalString (cfg.text.size.time != null)
      "--time-size=${toString cfg.text.size.time}")
    (optionalString (cfg.text.size.date != null)
      "--date-size=${toString cfg.text.size.date}")
    (optionalString (cfg.text.size.layout != null)
      "--layout-size=${toString cfg.text.size.layout}")
    (optionalString (cfg.text.size.verify != null)
      "--verif-size=${toString cfg.text.size.verify}")
    (optionalString (cfg.text.size.wrong != null)
      "--wrong-size=${toString cfg.text.size.wrong}")
    (optionalString (cfg.text.size.greeter != null)
      "--greeter-size=${toString cfg.text.size.greeter}")

    # colors
    (optionalString (cfg.colors.insideVerify != null)
      "--insidevercolor=${cfg.colors.insideVerify}")
    (optionalString (cfg.colors.ringVerify != null)
      "--ringvercolor=${cfg.colors.ringVerify}")
    (optionalString (cfg.colors.insideWrong != null)
      "--insidewrongcolor=${cfg.colors.insideWrong}")
    (optionalString (cfg.colors.ringWrong != null)
      "--ringwrongcolor=${cfg.colors.ringWrong}")
    (optionalString (cfg.colors.inside != null)
      "--insidecolor=${cfg.colors.inside}")
    (optionalString (cfg.colors.ring != null) "--ringcolor=${cfg.colors.ring}")
    (optionalString (cfg.colors.line != null) "--linecolor=${cfg.colors.line}")
    (optionalString (cfg.colors.separator != null)
      "--separatorcolor=${cfg.colors.separator}")
    (optionalString (cfg.colors.verify != null)
      "--verifcolor=${cfg.colors.verify}")
    (optionalString (cfg.colors.wrong != null)
      "--wrongcolor=${cfg.colors.wrong}")
    (optionalString (cfg.colors.time != null) "--timecolor=${cfg.colors.time}")
    (optionalString (cfg.colors.date != null) "--datecolor=${cfg.colors.date}")
    (optionalString (cfg.colors.layout != null)
      "--layoutcolor=${cfg.colors.layout}")
    (optionalString (cfg.colors.keyHold != null)
      "--keyhlcolor=${cfg.colors.keyHold}")
    (optionalString (cfg.colors.backspaceHold != null)
      "--bshlcolor=${cfg.colors.backspaceHold}")

    # if there are extra commands we want to run after, do not fork
    (optionalString (cfg.extraCommandsAfter != "") "--nofork")
  ]);

  lockScript = pkgs.writeScript "i3lock.sh" ''
    #!${pkgs.runtimeShell}
    ${cfg.extraCommandsBefore}
    ${lockCmd}
    ${cfg.extraCommandsAfter}
  '';

in {
  options.programs.i3lock = {
    enable = mkEnableOption "i3lock: a simple screen locker like slock.";

    cmd = mkOption {
      description = "Command to run for i3 lock.";
      type = types.path;
      default = "${pkgs.i3lock-color}/bin/i3lock-color";
      defaultText = "i3lock-color";
    };

    background = {
      color = mkOption {
        description = "Background color to use.";
        type = colorType;
        default = null;
      };

      image = mkOption {
        description = "Background image file to use.";
        type = types.nullOr types.path;
        default = null;
      };

      blur = mkOption {
        description = "Blur the current screen and use that as a background.";
        type = types.nullOr types.int;
        default = null;
      };
    };

    beep = mkOption {
      description = "Whether to enable beeping.";
      type = types.bool;
      default = false;
    };

    indicator = mkOption {
      description = "Whether to make indicator always be visible.";
      type = types.bool;
      default = false;
    };

    pointer = mkOption {
      description =
        "Whether to show mouse pointer, or display a hardcoded Windows-Pointer.";
      default = null;
      type = types.nullOr (types.enum [ "default" "win" ]);
    };

    clock = {
      enable = mkEnableOption "show clock";

      timeFormat = mkOption {
        description = "Clock time format to use.";
        type = types.str;
        default = "%H:%M:%S";
      };

      dateFormat = mkOption {
        description = "Clock date format to use.";
        type = types.str;
        default = "%A, %m %Y";
      };
    };

    text = {
      verify = mkOption {
        description = "Text to display while verifying.";
        type = types.nullOr types.str;
        default = null;
        example = "Drinking verification can...";
      };

      wrong = mkOption {
        description = "Text to display upon entering incorrect password.";
        type = types.nullOr types.str;
        default = null;
        example = "Nope!";
      };

      noInput = mkOption {
        description =
          "Text to display upon pressing backspace without anything to delete.";
        type = types.nullOr types.str;
        default = null;
      };

      lock = mkOption {
        description =
          "Text to display while acquiring pointer and keyboard focus.";
        type = types.nullOr types.str;
        default = null;
      };

      lockFailed = mkOption {
        description =
          "Text to display after failing to acquire pointer and keyboard focus.";
        type = types.nullOr types.str;
        default = null;
      };

      greeter = mkOption {
        description = "Text to display for greeter message.";
        type = types.nullOr types.str;
        default = null;
      };

      font = {
        time = mkOption {
          description = "Font to use for time text in the clock.";
          type = types.nullOr types.str;
          default = cfg.text.font.default;
        };

        date = mkOption {
          description = "Font to use for date text in the clock.";
          type = types.nullOr types.str;
          default = cfg.text.font.default;
        };

        layout = mkOption {
          description = "Font to use for displaying keyboard layout text.";
          type = types.nullOr types.str;
          default = cfg.text.font.default;
        };

        verify = mkOption {
          description = "Font to use for displaying text while verifying.";
          type = types.nullOr types.str;
          default = cfg.text.font.default;
        };

        wrong = mkOption {
          description =
            "Font use for status text upon entering incorrect password.";
          type = types.nullOr types.str;
          default = cfg.text.font.default;
        };

        greeter = mkOption {
          description = "Font to use for greeter text.";
          type = types.nullOr types.str;
          default = cfg.text.font.default;
        };

        default = mkOption {
          description = "Default font to use.";
          type = types.nullOr types.str;
          default = null;
        };
      };

      size = {
        time = mkOption {
          description = "Text size for time text in the clock.";
          type = types.nullOr types.int;
          default = cfg.text.size.default;
        };

        date = mkOption {
          description = "Text size for date text in the clock.";
          type = types.nullOr types.int;
          default = cfg.text.size.default;
        };

        layout = mkOption {
          description = "Text size to use for displaying keyboard layout text.";
          type = types.nullOr types.int;
          default = cfg.text.size.default;
        };

        verify = mkOption {
          description = "Text size to use for displaying text while verifying.";
          type = types.nullOr types.int;
          default = cfg.text.size.default;
        };

        wrong = mkOption {
          description =
            "Text size to use for status text upon entering incorrect password.";
          type = types.nullOr types.int;
          default = cfg.text.size.default;
        };

        greeter = mkOption {
          description = "Text size to use for greeter text.";
          type = types.nullOr types.int;
          default = cfg.text.size.default;
        };

        default = mkOption {
          description = "Default text size.";
          type = types.nullOr types.int;
          default = null;
        };
      };
    };

    colors = {
      inside = mkOption {
        description = "Color to use for interior circle while 'resting'.";
        type = colorType;
        default = null;
      };

      ring = mkOption {
        description = "Color to use for ring while 'resting'.";
        type = colorType;
        default = null;
      };

      insideVerify = mkOption {
        description = "Color to use for interior circle during verification.";
        type = colorType;
        default = null;
      };

      ringVerify = mkOption {
        description = "Color to use for ring during verification.";
        type = colorType;
        default = null;
      };

      insideWrong = mkOption {
        description =
          "Color to use for interior circle during flash for incorrect password.";
        type = colorType;
        default = null;
      };

      ringWrong = mkOption {
        description =
          "Color to use for ring during flash for incorrect password.";
        type = colorType;
        default = null;
      };

      line = mkOption {
        description =
          "Color to use for the line separating the inside circle, and the outer ring.";
        type = colorType;
        default = null;
      };

      separator = mkOption {
        description =
          "Color to use for 'separator', which is at both ends of the ring highlights..";
        type = colorType;
        default = null;
      };

      verify = mkOption {
        description = "Color to use for displaying text while verifying.";
        type = colorType;
        default = null;
      };

      wrong = mkOption {
        description =
          "Color to use for status text upon entering incorrect password.";
        type = colorType;
        default = null;
      };

      time = mkOption {
        description = "Color to use for time.";
        type = colorType;
        default = null;
      };

      date = mkOption {
        description = "Color to use for date.";
        type = colorType;
        default = null;
      };

      layout = mkOption {
        description = "Color to use for keyboard layout text.";
        type = colorType;
        default = null;
      };

      keyHold = mkOption {
        description =
          "Color to use for ring 'highlight' strokes that appear upon keypress.";
        type = colorType;
        default = null;
      };

      backspaceHold = mkOption {
        description =
          "Color to use for ring 'highlight' strokes that appear upon backspace.";
        type = colorType;
        default = null;
      };
    };

    extraCommandsBefore = mkOption {
      description = "Extra commands to run before running i3lock.";
      default = "";
      type = types.lines;
      example = literalExample ''
        ''${pkgs.scrot}/bin/scrot /tmp/screen_locked.png
        ''${pkgs.imagemagick}/bin/convert /tmp/screen_locked.png \
            -scale 10% -scale 1000% /tmp/screen_locked.png
      '';
    };

    extraCommandsAfter = mkOption {
      description = "Extra commands to run after running i3lock.";
      default = "";
      type = types.lines;
      example = literalExample ''
        ''${pkgs.systemd}/bin/systemctl --user restart setxkbmap.service
      '';
    };
  };

  config = mkIf cfg.enable {
    services.screen-locker = {
      enable = mkDefault true;
      lockCmd = mkDefault (toString lockScript);
    };
  };
}
