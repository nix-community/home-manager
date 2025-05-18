{
  config,
  lib,
  realPkgs,
  ...
}:

lib.mkIf config.test.enableBig {
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      settings = {
        globalOptions = {
          Behavior = {
            ActiveByDefault = false;
            resetStateWhenFocusIn = "No";
            ShareInputState = "No";
            PreeditEnabledByDefault = true;
            ShowInputMethodInformation = true;
            showInputMethodInformationWhenFocusIn = false;
            CompactInputMethodInformation = true;
            ShowFirstInputMethodInformation = true;
            DefaultPageSize = 5;
            OverrideXkbOption = false;
            PreloadInputMethod = true;
            AllowInputMethodForPassword = false;
            ShowPreeditForPassword = false;
            AutoSavePeriod = 30;
          };
          Hotkey = {
            EnumerateWithTriggerKeys = true;
            EnumerateSkipFirst = false;
            ModifierOnlyKeyTimeout = 250;
          };
        };
        inputMethod = {
          GroupOrder."0" = "Default";
          "Groups/0" = {
            Name = "Default";
            "Default Layout" = "us";
            DefaultIM = "pinyin";
          };
          "Groups/0/Items/0" = {
            Name = "keyboard-us";
            Layout = null;
          };
          "Groups/0/Items/1" = {
            Name = "pinyin";
            Layout = null;
          };
        };
        addons.classicui.globalSection.Theme = "example";
      };
      themes.example = {
        theme = ''
          [Metadata]
          Name=example
          Version=0.1
          Author=home-manager
          Description=Theme for testing
          ScaleWithDPI=True
        '';
      };
    };
  };

  _module.args.pkgs = lib.mkForce realPkgs;

  nmt.script = ''
    assertFileExists home-files/.config/systemd/user/fcitx5-daemon.service
    assertFileExists home-files/.config/fcitx5/config
    assertFileContent home-files/.config/fcitx5/config ${./config}
    assertFileExists home-files/.config/fcitx5/profile
    assertFileContent home-files/.config/fcitx5/profile ${./profile}
    assertFileExists home-files/.config/fcitx5/conf/classicui.conf
    assertFileContent home-files/.config/fcitx5/conf/classicui.conf ${./classicui.conf}
    assertFileExists home-files/.local/share/fcitx5/themes/example/theme.conf
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh 'GTK_IM_MODULE'
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh 'QT_IM_MODULE'
  '';
}
