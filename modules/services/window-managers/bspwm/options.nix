{ pkgs, lib }:

with lib;

let

  rule = types.submodule {
    options = {
      monitor = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The monitor where the rule should be applied.";
        example = "HDMI-0";
      };

      desktop = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The desktop where the rule should be applied.";
        example = "^8";
      };

      node = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The node where the rule should be applied.";
        example = "1";
      };

      state = mkOption {
        type = types.nullOr
          (types.enum [ "tiled" "pseudo_tiled" "floating" "fullscreen" ]);
        default = null;
        description = "The state in which a new window should spawn.";
        example = "floating";
      };

      layer = mkOption {
        type = types.nullOr (types.enum [ "below" "normal" "above" ]);
        default = null;
        description = "The layer where a new window should spawn.";
        example = "above";
      };

      splitDir = mkOption {
        type = types.nullOr (types.enum [ "north" "west" "south" "east" ]);
        default = null;
        description = "The direction where the container is going to be split.";
        example = "south";
      };

      splitRatio = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = ''
          The ratio between the new window and the previous existing window in
          the desktop.
        '';
        example = 0.65;
      };

      hidden = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Whether the node should occupy any space.";
        example = true;
      };

      sticky = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Whether the node should stay on the focused desktop.";
        example = true;
      };

      private = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          Whether the node should stay in the same tiling position and size.
        '';
        example = true;
      };

      locked = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          Whether the node should ignore <command>node --close</command>
          messages.
        '';
        example = true;
      };

      marked = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Whether the node will be marked for deferred actions.";
        example = true;
      };

      center = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          Whether the node will be put in the center, in floating mode.
        '';
        example = true;
      };

      follow = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Whether focus should follow the node when it is moved.";
        example = true;
      };

      manage = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          Whether the window should be managed by bspwm. If false, the window
          will be ignored by bspwm entirely. This is useful for overlay apps,
          e.g. screenshot tools.
        '';
        example = true;
      };

      focus = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Whether the node should gain focus on creation.";
        example = true;
      };

      border = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Whether the node should have border.";
        example = true;
      };
    };
  };

in {
  xsession.windowManager.bspwm = {
    enable = mkEnableOption "bspwm window manager.";

    package = mkOption {
      type = types.package;
      default = pkgs.bspwm;
      defaultText = literalExpression "pkgs.bspwm";
      description = "The bspwm package to use.";
      example = literalExpression "pkgs.bspwm-unstable";
    };

    settings = mkOption {
      type = with types;
        let primitive = either bool (either int (either float str));
        in attrsOf (either primitive (listOf primitive));
      default = { };
      description = "General settings given to <literal>bspc config</literal>.";
      example = {
        "border_width" = 2;
        "split_ratio" = 0.52;
        "gapless_monocle" = true;
      };
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description =
        "Additional shell commands to be run at the end of the config file.";
      example = ''
        bspc subscribe all > ~/bspc-report.log &
      '';
    };

    monitors = mkOption {
      type = types.attrsOf (types.listOf types.str);
      default = { };
      description =
        "Specifies the names of desktops to create on each monitor.";
      example = { "HDMI-0" = [ "web" "terminal" "III" "IV" ]; };
    };

    rules = mkOption {
      type = types.attrsOf rule;
      default = { };
      description =
        "Rule configuration. The keys of the attribute set are the targets of the rules.";
      example = literalExpression ''
        {
          "Gimp" = {
            desktop = "^8";
            state = "floating";
            follow = true;
          };
          "Kupfer.py" = {
            focus = true;
          };
          "Screenkey" = {
            manage = false;
          };
        }
      '';
    };

    startupPrograms = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Programs to be executed during startup.";
      example = [ "numlockx on" "tilda" ];
    };
  };
}
