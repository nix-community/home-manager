{ config, lib, pkgs, stdenv, ... }:

with lib;

let

  cfg = config.services.twmn;

  animationOpts = {
    curve = mkOption {
      type = types.ints.between 0 40;
      default = 38;
      example = 19;
      description = ''
        The qt easing-curve animation to use for the animation. See
        [
        QEasingCurve documentation](https://doc.qt.io/qt-5/qeasingcurve.html#Type-enum).
      '';
    };

    duration = mkOption {
      type = types.ints.unsigned;
      default = 1000;
      example = 618;
      description = "The animation duration in milliseconds.";
    };
  };

in {
  meta.maintainers = [ hm.maintainers.austreelis ];

  options.services.twmn = {
    enable = mkEnableOption "twmn, a tiling window manager notification daemon";

    duration = mkOption {
      type = types.ints.unsigned;
      default = 3000;
      example = 5000;
      description = ''
        The time each notification remains visible, in milliseconds.
      '';
    };

    extraConfig = mkOption {
      type = types.attrs;
      default = { };
      example = literalExpression
        ''{ main.activation_command = "\${pkgs.hello}/bin/hello"; }'';
      description = ''
        Extra configuration options to add to the twmnd config file. See
        <https://github.com/sboli/twmn/blob/master/README.md>
        for details.
      '';
    };

    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
      example = "laptop.lan";
      description = "Host address to listen on for notifications.";
    };

    icons = {
      critical = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to the critical notifications' icon.";
      };

      info = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to the informative notifications' icon.";
      };

      warning = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to the warning notifications' icon.";
      };
    };

    port = mkOption {
      type = types.port;
      default = 9797;
      description = "UDP port to listen on for notifications.";
    };

    screen = mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 0;
      description = ''
        Screen number to display notifications on when using a multi-head
        desktop.
      '';
    };

    soundCommand = mkOption {
      type = types.str;
      default = "";
      description = "Command to execute to play a notification's sound.";
    };

    text = {
      color = mkOption {
        type = types.str;
        default = "#999999";
        example = "lightgray";
        description = ''
          Notification's text color. RGB hex and keywords (e.g. `lightgray`)
          are supported.
        '';
      };

      font = {
        package = mkOption {
          type = types.nullOr types.package;
          default = null;
          example = literalExpression "pkgs.dejavu_fonts";
          description = ''
            Notification text's font package. If `null` then
            the font is assumed to already be available in your profile.
          '';
        };

        family = mkOption {
          type = types.str;
          default = "Sans";
          example = "Noto Sans";
          description = "Notification text's font family.";
        };

        size = mkOption {
          type = types.ints.unsigned;
          default = 13;
          example = 42;
          description = "Notification text's font size.";
        };

        variant = mkOption {
          # These are the font variant supported by twmn
          # See https://github.com/sboli/twmn/blob/master/README.md?plain=1#L42
          type = types.enum [
            "oblique"
            "italic"
            "ultra-light"
            "light"
            "medium"
            "semi-bold"
            "bold"
            "ultra-bold"
            "heavy"
            "ultra-condensed"
            "extra-condensed"
            "condensed"
            "semi-condensed"
            "semi-expanded"
            "expanded"
            "extra-expanded"
            "ultra-expanded"
          ];
          default = "medium";
          example = "heavy";
          description = "Notification text's font variant.";
        };
      };

      maxLength = mkOption {
        type = types.nullOr types.ints.unsigned;
        default = null;
        example = 80;
        description = ''
          Maximum length of the text before it is cut and suffixed with "...".
          Never cuts if `null`.
        '';
      };
    };

    window = {
      alwaysOnTop =
        mkEnableOption "forcing the notification window to always be on top";

      animation = {
        easeIn = mkOption {
          type = types.submodule { options = animationOpts; };
          default = { };
          example = literalExpression ''
            {
              curve = 19;
              duration = 618;
            }
          '';
          description = "Options for the notification appearance's animation.";
        };

        easeOut = mkOption {
          type = types.submodule { options = animationOpts; };
          default = { };
          example = literalExpression ''
            {
              curve = 19;
              duration = 618;
            }
          '';
          description =
            "Options for the notification disappearance's animation.";
        };

        bounce = {
          enable = mkEnableOption
            "notification bounce when displaying next notification directly";

          duration = mkOption {
            type = types.ints.unsigned;
            default = 500;
            example = 618;
            description = "The bounce animation duration in milliseconds.";
          };
        };
      };

      color = mkOption {
        type = types.str;
        default = "#000000";
        example = "lightgray";
        description = ''
          Notification's background color. RGB hex and keywords (e.g.
          `lightgray`) are supported.
        '';
      };

      height = mkOption {
        type = types.ints.unsigned;
        default = 18;
        example = 42;
        description = ''
          Height of the slide bar. Useful to match your tiling window
          manager's bar.
        '';
      };

      offset = {
        x = mkOption {
          type = types.int;
          default = 0;
          example = 50;
          description = ''
            Offset of the notification's slide starting point in pixels on the
            horizontal axis (positive is rightward).
          '';
        };

        y = mkOption {
          type = types.int;
          default = 0;
          example = -100;
          description = ''
            Offset of the notification's slide starting point in pixels on the
            vertical axis (positive is upward).
          '';
        };
      };

      opacity = mkOption {
        type = types.ints.between 0 100;
        default = 100;
        example = 80;
        description = "The notification window's opacity.";
      };

      position = mkOption {
        type = types.enum [
          "tr"
          "top_right"
          "tl"
          "top_left"
          "br"
          "bottom_right"
          "bl"
          "bottom_left"
          "tc"
          "top_center"
          "bc"
          "bottom_center"
          "c"
          "center"
        ];
        default = "top_right";
        example = "bottom_left";
        description = ''
          Position of the notification slide. The notification will slide
          in vertically from the border if placed in
          `top_center` or `bottom_center`,
          horizontally otherwise.
        '';
      };
    };
  };

  #################
  # Implementation

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.twmn" pkgs
        lib.platforms.linux)
    ];

    home.packages =
      lib.optional (!isNull cfg.text.font.package) cfg.text.font.package
      ++ [ pkgs.twmn ];

    xdg.configFile."twmn/twmn.conf".text = let
      conf = recursiveUpdate {
        gui = {
          always_on_top = if cfg.window.alwaysOnTop then "true" else "false";
          background_color = cfg.window.color;
          bounce =
            if cfg.window.animation.bounce.enable then "true" else "false";
          bounce_duration = toString cfg.window.animation.bounce.duration;
          font = cfg.text.font.family;
          font_size = toString cfg.text.font.size;
          font_variant = cfg.text.font.variant;
          foreground_color = cfg.text.color;
          height = toString cfg.window.height;
          in_animation = toString cfg.window.animation.easeIn.curve;
          in_animation_duration = toString cfg.window.animation.easeIn.duration;
          max_length = toString
            (if isNull cfg.text.maxLength then -1 else cfg.text.maxLength);
          offset_x = with cfg.window.offset;
            if x < 0 then toString x else "+${toString x}";
          offset_y = with cfg.window.offset;
            if y < 0 then toString y else "+${toString y}";
          opacity = toString cfg.window.opacity;
          out_animation = toString cfg.window.animation.easeOut.curve;
          out_animation_duration =
            toString cfg.window.animation.easeOut.duration;
          position = cfg.window.position;
          screen = toString cfg.screen;
        };
        # map null values to empty strings because formats.toml generator fails
        # when encountering a null.
        icons = mapAttrs (_: toString) cfg.icons;
        main = {
          duration = toString cfg.duration;
          host = cfg.host;
          port = toString cfg.port;
          sound_command = cfg.soundCommand;
        };
      } cfg.extraConfig;

      mkLine = name: value: "${name}=${value}";

      mkSection = section: conf: ''
        [${section}]
        ${concatStringsSep "\n" (mapAttrsToList mkLine conf)}
      '';
    in concatStringsSep "\n" (mapAttrsToList mkSection conf) + "\n";

    systemd.user.services.twmnd = {
      Unit = {
        Description = "twmn daemon";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
        X-Restart-Triggers =
          [ "${config.xdg.configFile."twmn/twmn.conf".source}" ];
      };

      Install.WantedBy = [ "graphical-session.target" ];

      Service = {
        ExecStart = "${pkgs.twmn}/bin/twmnd";
        Restart = "on-failure";
        Type = "simple";
        StandardOutput = "null";
      };
    };
  };
}
