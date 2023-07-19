{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.gromit-mpx;

  # Select the appropriate hot key:
  hotkey = if isInt cfg.hotKey then
    "--keycode ${toString cfg.hotKey}"
  else if cfg.hotKey != null then
    "--key ${cfg.hotKey}"
  else
    "--key none";

  # Select the appropriate undo key:
  undokey = if isInt cfg.undoKey then
    "--undo-keycode ${toString cfg.undoKey}"
  else if cfg.undoKey != null then
    "--undo-key ${cfg.undoKey}"
  else
    "--undo-key none";

  # The command line to send to gromit-mpx:
  commandArgs = concatStringsSep " " [ hotkey undokey ];

  # Gromit reads and writes from this file to store it's run time
  # state.  That will break our config so we set it manually which,
  # thanks to the read-only Nix store, prevents Gromit from writing to
  # it.
  keyFile = generators.toINI { } {
    General.ShowIntroOnStartup = false;
    Drawing.Opacity = cfg.opacity;
  };

  # Allowed modifiers:
  modsAndButtons = [ "1" "2" "3" "4" "5" "SHIFT" "CONTROL" "ALT" "META" ];

  # Create a string of tool attributes:
  toolAttrs = tool:
    concatStringsSep " " ([ "size=${toString tool.size}" ]
      ++ optional (tool.type != "eraser") ''color="${tool.color}"''
      ++ optional (tool.arrowSize != null)
      "arrowsize=${toString tool.arrowSize}");

  # Optional tool modifier string:
  toolMod = tool:
    if tool.modifiers != [ ] then
      "[" + concatStringsSep ", " tool.modifiers + "]"
    else
      "";

  # A single tool configuration:
  toolToCfg = n: tool: ''
    "tool-${toString n}" = ${toUpper tool.type} (${toolAttrs tool});
    "${tool.device}"${toolMod tool} = "tool-${toString n}";
  '';

  # Per-tool options:
  toolOptions = {
    options = {
      device = mkOption {
        type = types.str;
        example = "default";
        description = ''
          Use this tool with the given xinput device.  The device with
          the name default works with any input.
        '';
      };

      type = mkOption {
        type = types.enum [ "pen" "eraser" "recolor" ];
        default = "pen";
        example = "eraser";
        description = "Which type of tool this is.";
      };

      color = mkOption {
        type = types.str;
        default = "red";
        example = "#ff00ff";
        description = "The stroke (or recolor) color of the tool.";
      };

      size = mkOption {
        type = types.ints.positive;
        default = 5;
        example = 3;
        description = "The tool size.";
      };

      arrowSize = mkOption {
        type = types.nullOr types.ints.positive;
        default = null;
        example = 2;
        description = ''
          If not `null`, automatically draw an arrow
          at the end of a stroke with the given size.
        '';
      };

      modifiers = mkOption {
        type = types.listOf (types.enum modsAndButtons);
        default = [ ];
        example = [ "SHIFT" ];
        description = ''
          Only activate this tool if the given modifiers are also active.
        '';
      };
    };
  };

in {
  meta.maintainers = [ maintainers.pjones ];

  options.services.gromit-mpx = {
    enable = mkEnableOption "Gromit-MPX annotation tool";

    package = mkOption {
      type = types.package;
      default = pkgs.gromit-mpx;
      defaultText = "pkgs.gromit-mpx";
      description = "The gromit-mpx package to use.";
    };

    hotKey = mkOption {
      type = with types; nullOr (either str ints.positive);
      default = "F9";
      example = "Insert";
      description = ''
        A keysym or raw keycode that toggles the activation state of
        gromit-mpx.  Set to `null` to disable the
        hotkey in which case you'll have to activate gromit-mpx
        manually using the command line.
      '';
    };

    undoKey = mkOption {
      type = with types; nullOr (either str ints.positive);
      default = "F10";
      description = ''
        A keysym or raw keycode that causes gromit-mpx to undo the
        last stroke.  Use this key along with the shift key to redo an
        undone stoke.  Set to `null` to disable the
        undo hotkey.
      '';
    };

    opacity = mkOption {
      type = types.addCheck types.float (f: f >= 0.0 && f <= 1.0) // {
        description = "float between 0.0 and 1.0 (inclusive)";
      };
      default = 0.75;
      example = 1.0;
      description = "Opacity of the drawing overlay.";
    };

    tools = mkOption {
      type = types.listOf (types.submodule toolOptions);
      default = [
        {
          device = "default";
          type = "pen";
          size = 5;
          color = "red";
        }
        {
          device = "default";
          type = "pen";
          size = 5;
          color = "blue";
          modifiers = [ "SHIFT" ];
        }
        {
          device = "default";
          type = "pen";
          size = 5;
          color = "yellow";
          modifiers = [ "CONTROL" ];
        }
        {
          device = "default";
          type = "pen";
          size = 6;
          color = "green";
          arrowSize = 1;
          modifiers = [ "2" ];
        }
        {
          device = "default";
          type = "eraser";
          size = 75;
          modifiers = [ "3" ];
        }
      ];
      description = ''
        Tool definitions for gromit-mpx to use.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.gromit-mpx" pkgs
        lib.platforms.linux)
    ];

    xdg.configFile."gromit-mpx.ini".text = keyFile;
    xdg.configFile."gromit-mpx.cfg".text =
      concatStringsSep "\n" (imap1 toolToCfg cfg.tools);

    home.packages = [ cfg.package ];

    systemd.user.services.gromit-mpx = {
      Unit = {
        Description = "Gromit-MPX";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
        X-Restart-Triggers = [
          "${config.xdg.configFile."gromit-mpx.cfg".source}"
          "${config.xdg.configFile."gromit-mpx.ini".source}"
        ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/gromit-mpx ${commandArgs}";
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };
    };
  };
}
