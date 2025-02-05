{ lib, pkgs, config, ... }: {
  meta.maintainers = [ lib.maintainers._0x5a4 ];

  options.wayland.windowManager.wayfire = let
    types = lib.types;

    configIniType = with types;
      let
        primitiveType = either str (either bool number);
        sectionType = attrsOf primitiveType;
      in attrsOf sectionType;
  in {
    enable =
      lib.mkEnableOption "Wayfire, a wayland compositor based on wlroots";

    package = lib.mkPackageOption pkgs "wayfire" {
      nullable = true;
      extraDescription = ''
        Set to `null` to not add any wayfire package to your path.
        This should be done if you want to use the NixOS wayfire module to install wayfire.
      '';
    };

    plugins = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs.wayfirePlugins; [ wf-shell ];
      defaultText =
        lib.literalExpression "with pkgs.wayfirePlugins; [ wf-shell ]";
      example = lib.literalExpression ''
        with pkgs.wayfirePlugins; [
          wcm
          wf-shell
          wayfire-plugins-extra
        ];
      '';
      description = ''
        Additional plugins to use with wayfire
      '';
    };

    xwayland.enable = lib.mkEnableOption "XWayland" // { default = true; };

    settings = lib.mkOption {
      type = types.submodule {
        freeformType = configIniType;

        options.core.plugins = lib.mkOption {
          type = types.separatedString " ";
          description = "Load the specified plugins";
        };
      };
      default = { };
      description = ''
        Wayfire configuration written in Nix.

        See <https://github.com/WayfireWM/wayfire/wiki/Configuration>
      '';
      example = lib.literalExpression ''
        {
          core.plugins = "command expo cube";
          command = {
            binding_terminal = "alacritty";
            command_terminal = "alacritty";
          };
        }
      '';
    };

    wf-shell = {
      enable = lib.mkEnableOption "Manage wf-shell Configuration";

      package = lib.mkPackageOption pkgs.wayfirePlugins "wf-shell" { };

      settings = lib.mkOption {
        type = configIniType;
        default = { };
        description = ''
          Wf-shell configuration written in Nix.

          See <https://github.com/WayfireWM/wf-shell/blob/master/wf-shell.ini.example>
        '';
        example = lib.literalExpression ''
          {
            panel = {
              widgets_left = "menu spacing4 launchers window-list";
              autohide = true;
            };
          }
        '';
      };
    };

    systemd = {
      enable = lib.mkEnableOption null // {
        default = true;
        description = ''
          Whether to enable {file}`wayfire-session.target` on
          wayfire startup. This links to {file}`graphical-session.target`}.
          Some important environment variables will be imported to systemd
          and D-Bus user environment before reaching the target, including
          - `DISPLAY`
          - `WAYLAND_DISPLAY`
          - `XDG_CURRENT_DESKTOP`
          - `NIXOS_OZONE_WL`
          - `XCURSOR_THEME`
          - `XCURSOR_SIZE`
        '';
      };

      variables = lib.mkOption {
        type = types.listOf types.str;
        default = [
          "DISPLAY"
          "WAYLAND_DISPLAY"
          "XDG_CURRENT_DESKTOP"
          "NIXOS_OZONE_WL"
          "XCURSOR_THEME"
          "XCURSOR_SIZE"
        ];
        example = [ "-all" ];
        description = ''
          Environment variables to be imported in the systemd & D-Bus user
          environment.
        '';
      };

      extraCommands = lib.mkOption {
        type = types.listOf types.str;
        default = [
          "systemctl --user stop wayfire-session.target"
          "systemctl --user start wayfire-session.target"
        ];
        description = "Extra commands to be run after D-Bus activation.";
      };
    };
  };

  config = let
    cfg = config.wayland.windowManager.wayfire;

    variables = builtins.concatStringsSep " " cfg.systemd.variables;
    extraCommands = builtins.concatStringsSep " "
      (map (f: "&& ${f}") cfg.systemd.extraCommands);
    systemdActivation =
      "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd ${variables} ${extraCommands}";

    finalPackage = pkgs.wayfire-with-plugins.override {
      wayfire = cfg.package;
      plugins = cfg.plugins;
    };
  in lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "wayland.windowManager.wayfire" pkgs
        lib.platforms.linux)
    ];

    home.packages = lib.mkIf (cfg.package != null) (lib.concatLists [
      (lib.singleton finalPackage)
      (lib.optional (cfg.xwayland.enable) pkgs.xwayland)
    ]);

    wayland.windowManager.wayfire = {
      settings = {
        autostart = lib.mkIf cfg.systemd.enable { inherit systemdActivation; };
        core = {
          plugins = lib.concatStringsSep " " (lib.concatLists [
            (lib.optional (cfg.systemd.enable) "autostart")
            (lib.optional (cfg.wf-shell.enable) "wayfire-shell")
          ]);
          xwayland = cfg.xwayland.enable;
        };
      };

      plugins = lib.optional cfg.wf-shell.enable cfg.wf-shell.package;
    };

    xdg.configFile."wayfire.ini".text = lib.generators.toINI { } cfg.settings;

    xdg.configFile."wf-shell.ini" = lib.mkIf cfg.wf-shell.enable {
      text = lib.generators.toINI { } cfg.wf-shell.settings;
    };

    systemd.user.targets.wayfire-session = lib.mkIf cfg.systemd.enable {
      Unit = {
        Description = "wayfire compositor session";
        Documentation = [ "man:systemd.special(7)" ];
        BindsTo = [ "graphical-session.target" ];
        Wants = [ "graphical-session-pre.target" ];
        After = [ "graphical-session-pre.target" ];
      };
    };

    systemd.user.targets.tray = {
      Unit = {
        Description = "Home Manager System Tray";
        Requires = [ "graphical-session-pre.target" ];
      };
    };
  };
}
