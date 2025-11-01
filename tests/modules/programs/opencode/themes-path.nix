{
  nmt.script = ''
    assertFileExists home-files/.config/opencode/themes/my-theme.json
    assertFileContent home-files/.config/opencode/themes/my-theme.json \
      ${./my-theme.json}
  '';
  programs.opencode = {
    enable = true;
    themes.my-theme = ./my-theme.json;
  };
}
