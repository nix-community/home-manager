{
  lib,
  pkgs,
  config,
  ...
}:
let
  function = import ./function.nix {
    inherit lib;
  };

  xmlFormat = pkgs.formats.xml { };

  cfg = config.wayland.windowManager.labwc;

  variables = builtins.concatStringsSep " " cfg.systemd.variables;
  extraCommands = builtins.concatStringsSep " " (map (f: "&& ${f}") cfg.systemd.extraCommands);
  systemdActivation = "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd ${variables} ${extraCommands}";
in
{
  meta.maintainers = [ lib.hm.maintainers.LesVu ];

  options.wayland.windowManager.labwc = {
    enable = lib.mkEnableOption "Labwc, a wayland window-stacking compositor";

    package = lib.mkPackageOption pkgs "labwc" {
      nullable = true;
      extraDescription = ''
        Set to `null` to use Nixos labwc package.
      '';
    };

    xwayland.enable = lib.mkEnableOption "XWayland" // {
      default = true;
    };

    rc = lib.mkOption {
      type = lib.types.submodule {
        freeformType = xmlFormat.type;
      };
      default = { };
      description = ''
        Config to configure labwc options.
        Use "@attributes" for attributes.
        See <https://labwc.github.io/labwc-config.5.html> for configuration.
      '';
      example = lib.literalExpression ''
        {
          theme = {
            name = "nord";
            cornerRadius = 8;
            font = {
              "@name" = "FiraCode";
              "@size" = "11";
            };
          };
          keyboard = {
            default = true;
            keybind = [
              # <keybind key="W-Return"><action name="Execute" command="foot"/></keybind>
              {
                "@key" = "W-Return";
                action = {
                  "@name" = "Execute";
                  "@command" = "foot";
                };
              }
              # <keybind key="W-Esc"><action name="Execute" command="loot"/></keybind>
              {
                "@key" = "W-Esc";
                action = {
                  "@name" = "Execute";
                  "@command" = "loot";
                };
              }
            ];
          };
        }
      '';
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      example = ''
        <tablet mapToOutput="" rotate="0" mouseEmulation="no">
          <!-- Active area dimensions are in mm -->
          <area top="0.0" left="0.0" width="0.0" height="0.0" />
          <map button="Tip" to="Left" />
          <map button="Stylus" to="Right" />
          <map button="Stylus2" to="Middle" />
        </tablet>
      '';
      description = "Extra lines appended to {file}`$XDG_CONFIG_HOME/labwc/rc.xml`.";
    };

    menu = lib.mkOption {
      type = lib.types.listOf xmlFormat.type;
      default = [ ];
      description = "Config to configure labwc menu";
      example = lib.literalExpression ''
        [
          {
            label = "pipemenu";
            menuId = "menu";
            execute = "/home/user/nix/scripts/pipe.sh";
          }
          {
            menuId = "client-menu";
            label = "Client Menu";
            icon = "";
            items = [
              {
                label = "Maximize";
                icon = "";
                action = {
                  name = "ToggleMaximize";
                };
              }
              {
                label = "Fullscreen";
                action = {
                  name = "ToggleFullscreen";
                };
              }
              {
                label = "Alacritty";
                action = {
                  name = "Execute";
                  command = "alacritty";
                };
              }
              {
                label = "Move Left";
                action = {
                  name = "SendToDesktop";
                  to = "left";
                };
              }
              {
                separator = { };
              }
              {
                label = "Workspace";
                menuId = "workspace";
                icon = "";
                items = [
                  {
                    label = "Move Left";
                    action = {
                      name = "SendToDesktop";
                      to = "left";
                    };
                  }
                ];
              }
              {
                separator = true;
              }
            ];
          }
        ];
      '';
    };

    autostart = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Command to autostart when labwc start.
      '';
      example = [
        "wayvnc &"
        "waybar &"
        "swaybg -c '#113344' >/dev/null 2>&1 &"
      ];
    };

    environment = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Environment variable to add when labwc start.
      '';
      example = [
        "XDG_CURRENT_DESKTOP=labwc:wlroots"
        "XKB_DEFAULT_LAYOUT=us"
      ];
    };

    systemd = {
      enable = lib.mkEnableOption null // {
        default = true;
        description = ''
          Whether to enable {file}`labwc-session.target` on
          labwc startup. This links to {file}`graphical-session.target`.
          Some important environment variables will be imported to systemd
          and D-Bus user environment before reaching the target, including
          - `DISPLAY`
          - `WAYLAND_DISPLAY`
          - `XDG_CURRENT_DESKTOP`
        '';
      };

      variables = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "DISPLAY"
          "WAYLAND_DISPLAY"
          "XDG_CURRENT_DESKTOP"
        ];
        example = [ "-all" ];
        description = ''
          Environment variables to be imported in the systemd & D-Bus user
          environment.
        '';
      };

      extraCommands = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "systemctl --user stop labwc-session.target"
          "systemctl --user start labwc-session.target"
        ];
        description = "Extra commands to be run after D-Bus activation.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "wayland.windowManager.labwc" pkgs lib.platforms.linux)
    ];

    home.packages = lib.mkIf (cfg.package != null) (
      [ cfg.package ] ++ lib.optional cfg.xwayland.enable pkgs.xwayland
    );

    xdg.configFile."labwc/rc.xml" = lib.mkIf (cfg.rc != { }) {
      text = function.generateXML "labwc_config" cfg.rc cfg.extraConfig;
    };

    xdg.configFile."labwc/menu.xml" = lib.mkIf (cfg.menu != [ ]) {
      text = function.generateXML "openbox_menu" cfg.menu "";
    };

    xdg.configFile."labwc/autostart".source = pkgs.writeShellScript "autostart" (
      ''
        ### This file was generated with Nix. Don't modify this file directly.

        ### AUTOSTART SERVICE ###
        ${lib.concatStringsSep "\n" cfg.autostart}

      ''
      + (lib.optionalString cfg.systemd.enable ''
        ### SYSTEMD INTEGRATION ###
        ${systemdActivation}
      '')
    );

    xdg.configFile."labwc/environment" = lib.mkIf (cfg.environment != [ ]) {
      text = lib.concatStringsSep "\n" (
        cfg.environment ++ (lib.optionals (!cfg.xwayland.enable) [ "WLR_XWAYLAND=" ])
      );
    };

    systemd.user.targets.labwc-session = lib.mkIf cfg.systemd.enable {
      Unit = {
        Description = "labwc compositor session";
        Documentation = [ "man:systemd.special(7)" ];
        BindsTo = [ "graphical-session.target" ];
        Wants = [ "graphical-session-pre.target" ];
        After = [ "graphical-session-pre.target" ];
      };
    };
  };
}
