{
  programs.opencode = {
    enable = true;
    themes = ./themes-bulk;
  };

  nmt.script = ''
    assertFileExists home-files/.config/opencode/themes/dark-theme.json
    assertFileExists home-files/.config/opencode/themes/light-theme.json
    assertFileContent home-files/.config/opencode/themes/dark-theme.json \
      ${./themes-bulk/dark-theme.json}
    assertFileContent home-files/.config/opencode/themes/light-theme.json \
      ${./themes-bulk/light-theme.json}
  '';
}
