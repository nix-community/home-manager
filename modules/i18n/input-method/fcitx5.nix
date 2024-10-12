{ config, pkgs, lib, ... }:

with lib;
with types;

let
  im = config.i18n.inputMethod;
  cfg = im.fcitx5;
  fcitx5Package =
    pkgs.libsForQt5.fcitx5-with-addons.override { inherit (cfg) addons; };

  inputItem = {
    options = {
      name = mkOption {
        type = str;
        description = ''
          Name of the input method
        '';
      };
      layout = mkOption {
        type = str;
        default = "";
        description = ''
          Override the group's default layout
        '';
      };
    };
  };

  inputGroup = {
    options = {
      name = mkOption {
        type = str;
        description = ''
          Name of this input group
        '';
      };
      defaultLayout = mkOption {
        type = str;
        description = ''
          Default keyboard layout for this group
        '';
      };
      defaultIm = mkOption {
        type = str;
        description = ''
          Default IM for this group
        '';
      };
      items = mkOption {
        type = listOf (submodule inputItem);
        description = ''
          List of individual input methods
        '';
      };
    };
  };

in {
  options = {
    i18n.inputMethod.fcitx5 = {
      addons = mkOption {
        type = with types; listOf package;
        default = [ ];
        example = literalExpression "with pkgs; [ fcitx5-rime ]";
        description = ''
          Enabled Fcitx5 addons.
        '';
      };

      inputs = mkOption {
        type = listOf (submodule inputGroup);
        description = ''
          List of input groups
        '';
        example = [{
          name = "Default";
          defaultLayout = "us";
          defaultIm = "mozc";
          items = [ { name = "keyboard-us"; } { name = "mozc"; } ];
        }];
        default = [ ];
      };
    };
  };

  config = mkIf (im.enabled == "fcitx5") {
    i18n.inputMethod.package = fcitx5Package;

    xdg.configFile."fcitx5/profile" = mkIf (im.fcitx5.inputs != [ ]) {
      text = ''
        ${concatStrings (lists.imap0 (i: v: ''
          [Groups/${toString i}]
          Name=${v.name}
          Default Layout=${v.defaultLayout}
          DefaultIM=${v.defaultIm}

          ${
            concatStrings (lists.imap0 (i2: v2: ''
              [Groups/${toString i}/Items/${toString i2}]
              Name=${v2.name}
              Layout=${v2.layout}
            '') v.items)
          } '') im.fcitx5.inputs)}
        [GroupOrder]
        ${concatStrings (lists.imap0 (i: v: ''
          ${toString i}=${v.name}
        '') im.fcitx5.inputs)}
      '';
    };

    home.sessionVariables = {
      GLFW_IM_MODULE = "ibus"; # IME support in kitty
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
      XMODIFIERS = "@im=fcitx";
      QT_PLUGIN_PATH =
        "$QT_PLUGIN_PATH\${QT_PLUGIN_PATH:+:}${fcitx5Package}/${pkgs.qt6.qtbase.qtPluginPrefix}";
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
