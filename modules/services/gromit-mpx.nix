{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;

  cfg = config.services.gromit-mpx;
  iniFormat = pkgs.formats.ini { };
  opacityOption = options.services.gromit-mpx.opacity;

  # Select the appropriate hot key:
  hotkey =
    if lib.isInt cfg.hotKey then
      "--keycode ${toString cfg.hotKey}"
    else if cfg.hotKey != null then
      "--key ${cfg.hotKey}"
    else
      "--key none";

  # Select the appropriate undo key:
  undokey =
    if lib.isInt cfg.undoKey then
      "--undo-keycode ${toString cfg.undoKey}"
    else if cfg.undoKey != null then
      "--undo-key ${cfg.undoKey}"
    else
      "--undo-key none";

  # The command line to send to gromit-mpx:
  commandArgs = lib.concatStringsSep " " [
    hotkey
    undokey
  ];

  # Allowed modifiers:
  modsAndButtons = [
    "1"
    "2"
    "3"
    "4"
    "5"
    "SHIFT"
    "CONTROL"
    "ALT"
    "META"
  ];

  # Create a string of tool attributes:
  toolAttrs =
    tool:
    lib.concatStringsSep " " (
      [ "size=${toString tool.size}" ]
      ++ lib.optional (tool.type != "eraser") ''color="${tool.color}"''
      ++ lib.optional (tool.arrowSize != null) "arrowsize=${toString tool.arrowSize}"
    );

  # Optional tool modifier string:
  toolMod =
    tool: if tool.modifiers != [ ] then "[" + lib.concatStringsSep ", " tool.modifiers + "]" else "";

  # A single tool configuration:
  toolToCfg = n: tool: ''
    "tool-${toString n}" = ${lib.toUpper tool.type} (${toolAttrs tool});
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
        type = types.enum [
          "pen"
          "eraser"
          "recolor"
        ];
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

in
{
  meta.maintainers = [ lib.maintainers.pjones ];

  options.services.gromit-mpx = {
    enable = lib.mkEnableOption "Gromit-MPX annotation tool";

    package = lib.mkPackageOption pkgs "gromit-mpx" { };

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
      visible = false;
      description = ''
        Deprecated drawing overlay opacity. Use
        {option}`services.gromit-mpx.iniSettings.Drawing.Opacity` instead.
      '';
    };

    iniSettings = mkOption {
      inherit (iniFormat) type;
      default = { };
      description = ''
        Settings written to {file}`$XDG_CONFIG_HOME/gromit-mpx.ini`.
      '';
    };

    cfgSettings = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Settings written to {file}`$XDG_CONFIG_HOME/gromit-mpx.cfg`.
        These settings are appended to the generated settings from
        {option}`services.gromit-mpx.tools`.
      '';
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

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.gromit-mpx" pkgs lib.platforms.linux)
    ];

    services.gromit-mpx.iniSettings = {
      General.ShowIntroOnStartup = lib.mkDefault false;
      Drawing.Opacity = lib.mkOverride opacityOption.highestPrio cfg.opacity;
    };

    warnings =
      lib.optional (opacityOption.highestPrio < (lib.mkOptionDefault { }).priority)
        "The option `services.gromit-mpx.opacity' defined in ${lib.showFiles opacityOption.files} has been renamed to `services.gromit-mpx.iniSettings.Drawing.Opacity'.";

    xdg.configFile = {
      "gromit-mpx.ini".source = iniFormat.generate "gromitmpx.ini" cfg.iniSettings;
      "gromit-mpx.cfg".text = lib.concatStringsSep "\n" (
        lib.filter (settings: settings != "") [
          (lib.concatStringsSep "\n" (lib.imap1 toolToCfg cfg.tools))
          cfg.cfgSettings
        ]
      );
    };

    home.packages = [ cfg.package ];

    systemd.user.services.gromit-mpx = {
      Unit = {
        Description = "Gromit-MPX";
        After = [ "graphical-session.target" ];
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

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
