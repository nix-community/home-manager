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
  iniFormat = pkgs.formats.ini { };
  iniGlobalFormat = pkgs.formats.iniWithGlobalSection { };
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

      quickPhrase = lib.mkOption {
        type = with lib.types; attrsOf str;
        default = { };
        example = lib.literalExpression ''
          {
            smile = "（・∀・）";
            angry = "(￣ー￣)";
          }
        '';
        description = "Quick phrases.";
      };

      quickPhraseFiles = lib.mkOption {
        type = with lib.types; attrsOf path;
        default = { };
        example = lib.literalExpression ''
          {
            words = ./words.mb;
            numbers = ./numbers.mb;
          }
        '';
        description = "Quick phrase files.";
      };

      settings = {
        globalOptions = lib.mkOption {
          type = lib.types.submodule {
            freeformType = iniFormat.type;
          };
          default = { };
          description = ''
            The global options in `config` file in ini format.
          '';
          example = lib.literalExpression ''
            {
              Behavior = {
                ActiveByDefault = false;
              };
              Hotkey = {
                EnumerateWithTriggerKeys = true;
                EnumerateSkipFirst = false;
                ModifierOnlyKeyTimeout = 250;
              };
            }
          '';
        };
        inputMethod = lib.mkOption {
          type = lib.types.submodule {
            freeformType = iniFormat.type;
          };
          default = { };
          description = ''
            The input method configure in `profile` file in ini format.
          '';
          example = lib.literalExpression ''
            {
              GroupOrder."0" = "Default";
              "Groups/0" = {
                Name = "Default";
                "Default Layout" = "us";
                DefaultIM = "pinyin";
              };
              "Groups/0/Items/0".Name = "keyboard-us";
              "Groups/0/Items/1".Name = "pinyin";
            }
          '';
        };
        addons = lib.mkOption {
          type = with lib.types; (attrsOf iniGlobalFormat.type);
          default = { };
          description = ''
            The addon configures in `conf` folder in ini format with global sections.
            Each item is written to the corresponding file.
          '';
          example = lib.literalExpression ''
            {
              classicui.globalSection.Theme = "example";
              pinyin.globalSection.EmojiEnabled = "True";
            }
          '';
        };
      };

      ignoreUserConfig = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Ignore the user configures. **Warning**: When this is enabled, the
          user config files are totally ignored and the user dict can't be saved
          and loaded.
        '';
      };

      themes = lib.mkOption {
        type =
          with lib.types;
          lazyAttrsOf (submodule {
            options = {
              theme = lib.mkOption {
                type =
                  with lib.types;
                  nullOr (oneOf [
                    iniFormat.type
                    lines
                    path
                  ]);
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

  config = lib.mkIf (im.enable && im.type == "fcitx5") {
    i18n.inputMethod = {
      package = fcitx5Package;

      fcitx5.addons =
        lib.optionals (cfg.quickPhrase != { }) [
          (pkgs.writeTextDir "share/fcitx5/data/QuickPhrase.mb" (
            lib.concatStringsSep "\n" (
              lib.mapAttrsToList (
                name: value: "${name} ${builtins.replaceStrings [ "\\" "\n" ] [ "\\\\" "\\n" ] value}"
              ) cfg.quickPhrase
            )
          ))
        ]
        ++ lib.optionals (cfg.quickPhraseFiles != { }) [
          (pkgs.linkFarm "quickPhraseFiles" (
            lib.mapAttrs' (
              name: value: lib.nameValuePair ("share/fcitx5/data/quickphrase.d/${name}.mb") value
            ) cfg.quickPhraseFiles
          ))
        ];
    };

    home = {
      sessionVariables = {
        GLFW_IM_MODULE = "ibus"; # IME support in kitty
        SDL_IM_MODULE = "fcitx";
        XMODIFIERS = "@im=fcitx";
      }
      // lib.optionalAttrs (!cfg.waylandFrontend) {
        GTK_IM_MODULE = "fcitx";
        QT_IM_MODULE = "fcitx";
      }
      // lib.optionalAttrs cfg.ignoreUserConfig {
        SKIP_FCITX_USER_PATH = "1";
      };

      sessionSearchVariables.QT_PLUGIN_PATH = [ "${fcitx5Package}/${pkgs.qt6.qtbase.qtPluginPrefix}" ];
    };

    xdg = {
      configFile.fcitx5 =
        let
          optionalFile =
            p: f: v:
            lib.optionalAttrs (v != { }) {
              ${p} = f "fcitx5-${builtins.replaceStrings [ "/" ] [ "-" ] p}" v;
            };
          entries = lib.attrsets.mergeAttrsList [
            (optionalFile "config" iniFormat.generate cfg.settings.globalOptions)
            (optionalFile "profile" iniFormat.generate cfg.settings.inputMethod)
            (lib.concatMapAttrs (
              name: value: optionalFile "conf/${name}.conf" iniGlobalFormat.generate value
            ) cfg.settings.addons)
          ];
        in
        lib.mkIf (entries != { }) { source = pkgs.linkFarm "fcitx-config" entries; };

      dataFile = lib.concatMapAttrs (
        name: attrs:
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
            else if builtins.isString attrs.theme then
              pkgs.writeText "fcitx5-theme.conf" attrs.theme
            else
              iniFormat.generate "fcitx5-${name}-theme" attrs.theme
          ))
        ]
      ) cfg.themes;
    };

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
