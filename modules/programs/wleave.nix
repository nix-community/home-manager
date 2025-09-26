{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.wleave;

  jsonFormat = pkgs.formats.json { };
in
{
  meta.maintainers = [ lib.maintainers.jaredmontoya ];

  options.programs.wleave = with lib.types; {
    enable = lib.mkEnableOption "wleave";

    package = lib.mkPackageOption pkgs "wleave" { nullable = true; };

    settings = lib.mkOption {
      inherit (jsonFormat) type;
      default = { };
      description = ''
        Configuration for wleave.
        See <https://github.com/AMNatty/wleave#configuration> for supported values.
      '';
      example = lib.literalExpression ''
        {
          margin = 200;
          buttons-per-row = "1/1";
          delay-command-ms = 100;
          close-on-lost-focus = true;
          show-keybinds = true;
          buttons = [
            {
              label = "lock";
              action = "swaylock";
              text = "Lock";
              keybind = "l";
              icon = "''${pkgs.wleave}/share/wleave/icons/lock.svg";
            }
            {
              label = "logout";
              action = "loginctl terminate-user $USER";
              text = "Logout";
              keybind = "e";
              icon = "''${pkgs.wleave}/share/wleave/icons/logout.svg";
            }
            {
              label = "shutdown";
              action = "systemctl poweroff";
              text = "Shutdown";
              keybind = "s";
              icon = "''${pkgs.wleave}/share/wleave/icons/shutdown.svg";
            }
          ];
        }
      '';
    };

    style = lib.mkOption {
      type = nullOr (either path lines);
      default = null;
      description = ''
        CSS style of wleave.

        See <https://github.com/AMNatty/wleave#styling>
        for the documentation.

        If the value is set to a path literal, then the path will be used as the css file.
      '';
      example = ''
        window {
          background-color: rgba(12, 12, 12, 0.8);
        }

        button {
          color: var(--view-fg-color);
          background-color: var(--view-bg-color);
          border: none;
          padding: 10px;
        }

        button:hover,
        button:focus {
          color: var(--accent-color);
          background-color: var(--window-bg-color);
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.wleave" pkgs lib.platforms.linux)
    ];

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."wleave/layout.json" = lib.mkIf (cfg.settings != { }) {
      source = pkgs.writeText "wleave-layout.json" ((builtins.toJSON cfg.settings) + "\n");
    };

    xdg.configFile."wleave/style.css" = lib.mkIf (cfg.style != null) {
      source =
        if builtins.isPath cfg.style || lib.isStorePath cfg.style then
          cfg.style
        else
          pkgs.writeText "wleave-style.css" cfg.style;
    };
  };
}
