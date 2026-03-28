{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.wayland.windowManager.niri;
in
{
  meta.maintainers = with lib.hm.maintainers; [ lukasngl ];

  options.wayland.windowManager.niri = {
    enable = lib.mkEnableOption "niri";

    package = lib.mkPackageOption pkgs "niri" {
      nullable = true;
      extraDescription = ''
        Set to `null` to not add any niri package to your path.
      '';
    };

    systemd = {
      enable = lib.mkEnableOption "systemd" // {
        default = true;
        description = ''
          Whether to install niri's systemd units from the {option}`package`,
          that are used by {command}`niri-session`.
        '';
      };

      # Note: this option is expected to be present by way-display.
      variables = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          Environment variables to be imported in the systemd & D-Bus user
          environment. Not used by niri, as {command}`niri-session` already
          imports all environment variables.
        '';
      };

    };

    xwaylandSatellite = lib.mkPackageOption pkgs "xwayland-satellite" {
      nullable = true;
      extraDescription = ''
        With `xwayland-satellite` in the {env}`$PATH`, niri can automatically
        start XWayland when needed. Set to `null` if you want to disable xwayland.
        See <https://yalter.github.io/niri/Xwayland.html>.
      '';
    };

    portalPackage = lib.mkPackageOption pkgs "xdg-desktop-portal-gnome" {
      nullable = true;
      extraDescription = ''
        The portal implementation to use with niri. Niri ships a portal
        configuration that prefers `gnome` and `gtk` portals.
        Set to `null` to not install any portal package.
      '';
    };

    checkConfig = lib.mkOption {
      type = lib.types.bool;
      default = cfg.package != null;
      defaultText = lib.literalExpression "wayland.windowManager.niri.package != null";
      description = "If enabled and package is not null, validates the generated config file.";
    };

    settings = lib.mkOption {
      type =
        with lib.types;
        let
          valueType =
            nullOr (oneOf [
              bool
              int
              float
              str
              (attrsOf valueType)
              (listOf valueType)
            ])
            // {
              description = "KDL value";
            };
        in
        attrsOf valueType;
      default = { };
      example = lib.literalExpression ''
        {
          # str/num/bool → single argument
          screenshot-path = "~/Screenshots/%Y-%m-%d %H-%M-%S.png";
          layout.gaps = 8;
          layout.shadow.draw-behind-window = true;

          # {} → leaf node
          prefer-no-csd = {};
          input.touchpad.tap = {};

          # _props → named properties: offset x=0 y=5
          layout.shadow.offset._props = { x = 0; y = 5; };

          # _children → ordered/repeated children
          layout.preset-column-widths._children = [
            { proportion = 0.33333; }
            { proportion = 0.5; }
          ];

          # _props + list args in binds
          binds = {
            "Mod+H".focus-column-left = {};
            "Mod+Return" = {
              _props.hotkey-overlay-title = "Open a Terminal";
              spawn = ["ghostty"];
            };
            "XF86AudioRaiseVolume" = {
              _props.allow-when-locked = true;
              spawn = ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"];
            };
          };

          # _args for repeated/parameterized top-level nodes
          _children = [
            { workspace._args = ["chat"]; }
            { workspace._args = ["dev"]; }
            # _args + children
            { output = { _args = ["eDP-1"]; scale = 2.0; }; }
            # nested _children + _props
            {
              window-rule._children = [
                { match._props = { app-id = "firefox"; at-startup = true; }; }
                { open-on-workspace = "dev"; }
              ];
            }
          ];
        }
      '';
      description = ''
        Configuration added to {file}`$XDG_CONFIG_HOME/niri/config.kdl`.
        See <https://yalter.github.io/niri/Configuration%3A-Introduction.html> for the full list of options.
      '';
    };

    extraConfigEarly = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra configuration lines added to {file}`$XDG_CONFIG_HOME/niri/config.kdl` before config generated from the options.";
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra configuration lines added to {file}`$XDG_CONFIG_HOME/niri/config.kdl` after the config generated from the options.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "wayland.windowManager.niri" pkgs lib.platforms.linux)
      {
        assertion = cfg.systemd.enable -> cfg.package != null;
        message = "wayland.windowManager.niri.systemd.enable requires a non-null package";
      }
      {
        assertion = cfg.checkConfig -> cfg.package != null;
        message = "wayland.windowManager.niri.checkConfig requires a non-null package";
      }
    ];

    home.packages = lib.concatLists [
      (lib.optional (cfg.package != null) cfg.package)
      (lib.optional (cfg.xwaylandSatellite != null) cfg.xwaylandSatellite)
    ];

    systemd.user.packages = lib.optional cfg.systemd.enable cfg.package;

    xdg.portal = lib.mkIf (cfg.portalPackage != null) {
      enable = true;
      extraPortals = [ cfg.portalPackage ];
      configPackages = lib.optional (cfg.package != null) cfg.package;
    };

    xdg.configFile."niri/config.kdl" =
      let
        settings = pkgs.lib.trim (lib.hm.generators.toKDL { } cfg.settings);
        text = lib.concatStringsSep "" [
          (lib.optionalString (cfg.extraConfigEarly != "") ''
            // Automatically generated by home-manager from `wayland.windowManager.niri.extraConfigEarly`
            ${cfg.extraConfigEarly}
          '')
          (lib.optionalString (settings != "") ''
            // Automatically generated by home-manager from `wayland.windowManager.niri.settings`
            ${settings}
          '')
          (lib.optionalString (cfg.extraConfig != "") ''
            // Automatically generated by home-manager from `wayland.windowManager.niri.extraConfig`
            ${cfg.extraConfig}
          '')
        ];
      in
      lib.mkIf (text != "") {
        source = pkgs.writeTextFile {
          name = "niri-config.kdl";
          inherit text;
          checkPhase = lib.optionalString cfg.checkConfig ''
            ${lib.getExe cfg.package} validate --config "$target"
          '';
        };
      };

  };
}
