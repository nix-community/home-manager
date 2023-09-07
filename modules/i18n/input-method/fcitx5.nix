{ config, pkgs, lib, ... }:

with lib;

let
  im = config.i18n.inputMethod;
  cfg = im.fcitx5;
  fcitx5Package = pkgs.fcitx5-with-addons.override { inherit (cfg) addons; };
  settingsFormat = pkgs.formats.ini { };
in {
  options = {
    i18n.inputMethod.fcitx5 = {
      addons = mkOption {
        type = with types; listOf package;
        default = [ ];
        example = literalExpression "with pkgs; [ fcitx5-rime ]";
        description = mdDoc ''
          Enabled Fcitx5 addons.
        '';
      };
      quickPhrase = mkOption {
        type = with types; attrsOf str;
        default = { };
        example = literalExpression ''
          {
            smile = "（・∀・）";
            angry = "(￣ー￣)";
          }
        '';
        description = mdDoc "Quick phrases.";
      };
      quickPhraseFiles = mkOption {
        type = with types; attrsOf path;
        default = { };
        example = literalExpression ''
          {
            words = ./words.mb;
            numbers = ./numbers.mb;
          }
        '';
        description = mdDoc "Quick phrase files.";
      };
      settings = {
        globalOptions = mkOption {
          type = types.submodule {
            freeformType = settingsFormat.type;
          };
          default = { };
          description = mdDoc ''
            The global options in `config` file in ini format.
          '';
        };
        inputMethod = mkOption {
          type = types.submodule {
            freeformType = settingsFormat.type;
          };
          default = { };
          description = mdDoc ''
            The input method configure in `profile` file in ini format.
          '';
        };
        addons = mkOption {
          type = with types; (attrsOf anything);
          default = { };
          description = mdDoc ''
            The addon configures in `conf` folder in ini format with global sections.
            Each item is written to the corresponding file.
          '';
          example = literalExpression "{ pinyin.globalSection.EmojiEnabled = \"True\"; }";
        };
      };
    };
  };

  config = mkIf (im.enabled == "fcitx5") {
    i18n.inputMethod.package = fcitx5Package;

    i18n.inputMethod.fcitx5.addons = optionals (cfg.quickPhrase != { }) [
      (pkgs.writeTextDir "share/fcitx5/data/QuickPhrase.mb"
        (concatStringsSep "\n"
          (mapAttrsToList (name: value: "${name} ${value}") cfg.quickPhrase)))
    ] ++ optionals (cfg.quickPhraseFiles != { }) [
      (pkgs.linkFarm "quickPhraseFiles" (mapAttrs'
        (name: value: nameValuePair ("share/fcitx5/data/quickphrase.d/${name}.mb") value)
        cfg.quickPhraseFiles))
    ];

    xdg.configFile =
      let
        optionalFile = p: f: v: optionalAttrs (v != { }) {
          "fcitx5/${p}".source = pkgs.writeTextFile {
            name = p;
            text = f v;
          };
        };
      in
      attrsets.mergeAttrsList [
        (optionalFile "config" (generators.toINI { }) cfg.settings.globalOptions)
        (optionalFile "profile" (generators.toINI { }) cfg.settings.inputMethod)
        (concatMapAttrs
          (name: value: optionalFile
            "conf/${name}.conf"
            (generators.toINIWithGlobalSection { })
            value)
          cfg.settings.addons)
      ];

    home.sessionVariables = {
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
      XMODIFIERS = "@im=fcitx";
      QT_PLUGIN_PATH = "$QT_PLUGIN_PATH:${fcitx5Package}/${pkgs.qt6.qtbase.qtPluginPrefix}";
    };

    systemd.user.services.fcitx5-daemon = {
      Unit = {
        Description = "Fcitx5 input method editor";
        PartOf = [ "graphical-session.target" ];
      };
      Service.ExecStart = "${fcitx5Package}/bin/fcitx5";
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };

}
