{
  pkgs,
  config,
  lib,
  ...
}:
let

  inherit (lib.options) mkEnableOption mkPackageOption mkOption;
  cfg = config.wayland.windowManager.pinnacle;
  settingsFormat = pkgs.formats.toml { };

  systemdModule = {
    options = {
      enable = mkOption {
        default = true;
        example = true;
        type = lib.types.bool;
        description = ''
          create and enable the systemd user service to manage pinnacle. not enabling this option means you will need to create the user service/shutdown target yourself.
        '';
      };
      useService = mkOption {
        default = true;
        example = true;
        type = lib.types.bool;
        description = "use a systemd service rather than a target -- needed for the provided pinnacle-session command but not necessary if using UWSM to manage the pinnacle session.";
      };
      xdgAutostart = mkEnableOption "autostart xdg applications";
    };
  };
in
{
  meta.maintainers = [ pkgs.lib.maintainers.cassandracomar ];

  options.wayland.windowManager.pinnacle = {
    enable = mkEnableOption "pinnacle";

    package = mkPackageOption pkgs "pinnacle" {
      default = "pinnacle";
      example = "pkgs.pinnacle";
      extraDescription = "package containing the pinnacle server binary";
    };

    clientPackage = mkPackageOption pkgs "pinnacle-config" {
      default = "pinnacle-config";
      example = "pkgs.pinnacle-config";
      extraDescription = "package containing the command/script to run as the pinnacle user configuration.";
    };

    config = {
      execCmd = mkOption {
        type = lib.types.listOf (
          lib.types.oneOf (
            with lib.types;
            [
              str
              path
            ]
          )
        );
        defaultText = lib.literalExpression ''["''${config.wayland.windowManager.pinnacle.clientPackage}/bin/pinnacle-config''']'';
        example = ''["''${pkgs.pinnacle-config}/bin/pinnacle-config"]'';
        description = ''
          the command to run for the pinnacle user configuration, provided via the pinnacle config toml file to the pinnacle server binary.
          you can provide this package via a nixpkgs overlay like:

          ```nix
            pkgs = import nixpkgs {
              inherit system;
              overlays = [
                (final: prev: {
                  pinnacle-config = prev.pinnacle.buildRustConfig {
                    pname = "pinnacle-config";
                    version = "0.2.0";
                    src = ./.;
                  };
                })
              ];
            };
          ```

          or by setting the package option directly.

          please note that if you're running this home-manager module on a non-NixOS distribution and making use of snowcap, you either need to enable [non-nixos gpu
          configuration](https://github.com/nix-community/home-manager/blob/master/docs/manual/usage/gpu-non-nixos.md) or wrap the call to pinnacle in nixGL.
        '';
      };
      nixGL = {
        enable = mkEnableOption ''
          wrap the pinnacle package with nixGL. this should only be enabled on non-NixOS systems. you will need to configure nixGL within your home-manager config.

          example for intel/amd igpu + nvidia discrete gpu:
          ```nix
            nixGL = {
              packages = nixgl.packages;
              defaultWrapper = "mesa";
              offloadWrapper = "nvidiaPrime";
              vulkan.enable = true;
              installScripts = ["mesa" "nvidiaPrime"];
            };
          ```
        '';
      };
      xdg-portals.enable = mkEnableOption "set up xdg desktop portals";
    };

    systemd = lib.mkOption {
      type = lib.types.submodule systemdModule;
      description = "systemd configuration options";
    };

    extraSettings = mkOption {
      type = lib.types.attrs;

      default = { };

      example = ''
        ```nix
          wayland.windowManager.pinnacle.extraSettings = {
            env = {
              "MY_ENV_VAR" = "super special env var";
            };
          };
        ```
      '';

      description = ''
        the pinnacle.toml configuration settings exposed as a nix attrset -- these are merged with the settings exposed under the `config` attr.

        see: https://pinnacle-comp.github.io/pinnacle/
      '';
    };

    mergedSettings = mkOption {
      internal = true;
      inherit (settingsFormat) type;
      default = {
        run = cfg.config.execCmd;
      }
      // cfg.extraSettings;
    };
  };

  config =
    let
      configFile = settingsFormat.generate "pinnacle.toml" cfg.mergedSettings;
      package = if cfg.config.nixGL.enable then config.lib.nixGL.wrap cfg.package else cfg.package;
    in
    lib.mkIf cfg.enable {
      home.packages = [
        package
        cfg.clientPackage
        pkgs.protobuf
        pkgs.xwayland
      ];
      xdg.portal = lib.mkIf cfg.config.xdg-portals.enable {
        enable = true;
        configPackages = [ package ];
        extraPortals = [
          pkgs.xdg-desktop-portal-wlr
          pkgs.xdg-desktop-portal-gtk
          pkgs.gnome-keyring
        ];
      };

      xdg.configFile."pinnacle/pinnacle.toml" = {
        source = configFile;
        onChange = ''
          PATH="${pkgs.protobuf}/bin:''${PATH}" ${package}/bin/pinnacle client -e "Pinnacle.reload_config()"
        '';
      };

      xdg.dataFile = {
        "pinnacle" = {
          source = config.lib.file.mkOutOfStoreSymlink "${cfg.package.lua-client-api}/share/pinnacle";
          force = true;
          onChange = ''
            PATH="${pkgs.protobuf}/bin:''${PATH}" ${package}/bin/pinnacle client -e "Pinnacle.reload_config()"
          '';
        };
      };

      systemd.user.services.pinnacle = lib.mkIf (cfg.systemd.enable && cfg.systemd.useService) {
        Unit = {
          Description = "A Wayland compositor inspired by AwesomeWM";
          BindsTo = [ "graphical-session.target" ];
          Wants = [
            "graphical-session-pre.target"
          ]
          ++ lib.optionals cfg.systemd.xdgAutostart [ "xdg-desktop-autostart.target" ];
          After = [ "graphical-session-pre.target" ];
          Before = [
            "graphical-session.target"
          ]
          ++ lib.optionals cfg.systemd.xdgAutostart [ "xdg-desktop-autostart.target" ];
          # don't restart every time we update home-manager/nixos -- the user should log out and back in to update to a new pinnacle binary.
          X-SwitchMethod = "reload";
        };
        Service = {
          Slice = [ "session.slice" ];
          Type = "notify";
          ExecStart = "${package}/bin/pinnacle --session";
          ExecReload = "${package}/bin/pinnacle client -e 'Pinnacle.reload_config()'";
        };
      };

      systemd.user.targets.pinnacle-shutdown = lib.mkIf (cfg.systemd.enable && cfg.systemd.useService) {
        Unit = {
          Description = "Shutdown running Pinnacle session";
          DefaultDependencies = false;
          StopWhenUnneeded = true;

          Conflicts = [
            "graphical-session.target"
            "graphical-session-pre.target"
          ];
          After = [
            "graphical-session.target"
            "graphical-session-pre.target"
          ];
        };
      };

      systemd.user.targets.pinnacle-session = lib.mkIf (cfg.systemd.enable && !cfg.systemd.useService) {
        Unit = {
          Description = "Pinnacle compositor session";
          Documentation = [ "man:systemd.special(7)" ];
          BindsTo = [ "graphical-session.target" ];
          Wants = [
            "graphical-session-pre.target"
          ]
          ++ lib.optionals cfg.systemd.xdgAutostart [ "xdg-desktop-autostart.target" ];
          After = [ "graphical-session-pre.target" ];
          Before = lib.optionals cfg.systemd.xdgAutostart [ "xdg-desktop-autostart.target" ];
        };
      };
    };
}
