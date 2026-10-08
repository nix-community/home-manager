{
  programs.concord = {
    enable = true;
    themeSettings = {
      highlight = {
        Normal = {
          foreground = "terminal_default";
          background = "terminal_default";
        };

        FocusBorder.foreground = "light_magenta";
        ComposerPickerBorder.link = "FocusBorder";
        Selection.background = "none";
      };

      ui.border = {
        default = "plain";
        composer = "rounded";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/concord/theme.toml
    assertFileContent home-files/.config/concord/theme.toml \
      ${./concord-theme.toml}
  '';
}
