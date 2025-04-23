{
  config,
  pkgs,
  lib,
  ...
}:
let
  im = config.i18n.inputMethod;
  cfg = im.fcitx5;
  fcitx5Package = cfg.fcitx5-with-addons.override { inherit (cfg) addons; };
in
{
  options = {
    i18n.inputMethod.fcitx5 = {
      fcitx5-with-addons = lib.mkOption {
        type = lib.types.package;
        default = pkgs.libsForQt5.fcitx5-with-addons;
        example = lib.literalExpression "pkgs.kdePackages.fcitx5-with-addons";
        description = ''
          The fcitx5 package to use.
        '';
      };
      addons = lib.mkOption {
        type = with lib.types; listOf package;
        default = [ ];
        example = lib.literalExpression "with pkgs; [ fcitx5-rime ]";
        description = ''
          Enabled Fcitx5 addons.
        '';
      };

      waylandFrontend = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Use the Wayland input method frontend.
          See [Using Fcitx 5 on Wayland](https://fcitx-im.org/wiki/Using_Fcitx_5_on_Wayland).
        '';
      };

      classicUiConfig = lib.mkOption {
        type = with lib.types; either path lines;
        default = "";
        description = ''
          Configuration to be written to {file}`$XDG_DATA_HOME/fcitx5/conf/classicui.conf`
        '';
      };

      themes = lib.mkOption {
        type =
          with lib.types;
          lazyAttrsOf (submodule {
            options = {
              theme = lib.mkOption {
                type = with lib.types; nullOr (either lines path);
                default = null;
                description = ''
                  The `theme.conf` file of the theme.

                  See https://fcitx-im.org/wiki/Fcitx_5_Theme#Background_images
                  for more information.
                '';
              };
              highlightImage = lib.mkOption {
                type = with lib.types; nullOr path;
                default = null;
                description = "Path to the SVG of the highlight.";
              };
              panelImage = lib.mkOption {
                type = with lib.types; nullOr path;
                default = null;
                description = "Path to the SVG of the panel.";
              };
            };
          });
        example = "";
        description = ''
          Themes to be written to {file}`$XDG_DATA_HOME/fcitx5/themes/''${name}`
        '';
        default = { };
      };
    };
  };

  config = lib.mkIf (im.enabled == "fcitx5") {
    i18n.inputMethod.package = fcitx5Package;

    home = {
      sessionVariables =
        {
          GLFW_IM_MODULE = "ibus"; # IME support in kitty
          SDL_IM_MODULE = "fcitx";
          XMODIFIERS = "@im=fcitx";
        }
        // lib.optionalAttrs (!cfg.waylandFrontend) {
          GTK_IM_MODULE = "fcitx";
          QT_IM_MODULE = "fcitx";
        };

      sessionSearchVariables.QT_PLUGIN_PATH = [ "${fcitx5Package}/${pkgs.qt6.qtbase.qtPluginPrefix}" ];
    };

    xdg = lib.mkMerge (
      [
        (lib.mkIf (cfg.classicUiConfig != "") {
          dataFile."fcitx5/conf/classicui.conf".source = (
            if builtins.isPath cfg.classicUiConfig || lib.isStorePath cfg.classicUiConfig then
              cfg.classicUiConfig
            else
              pkgs.writeText "fcitx5-classicui.conf" cfg.classicUiConfig
          );
        })
      ]
      ++ lib.mapAttrsToList (name: attrs: {
        dataFile =
          let
            nullableFile =
              n: maybeNull: source:
              lib.nameValuePair "fcitx5/themes/${name}/${n}" (lib.mkIf (maybeNull != null) { inherit source; });
            simpleFile = n: v: nullableFile n v v;
          in
          builtins.listToAttrs [
            (simpleFile "highlight.svg" attrs.highlightImage)
            (simpleFile "panel.svg" attrs.panelImage)
            (nullableFile "theme.conf" attrs.theme (
              if builtins.isPath attrs.theme || lib.isStorePath attrs.theme then
                attrs.theme
              else
                pkgs.writeText "fcitx5-theme.conf" attrs.theme
            ))
          ];
      }) cfg.themes
    );

    systemd.user.services.fcitx5-daemon = {
      Unit = {
        Description = "Fcitx5 input method editor";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service.ExecStart = "${fcitx5Package}/bin/fcitx5";
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
