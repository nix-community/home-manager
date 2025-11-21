{
  programs.eza = {
    enable = true;
    theme = {
      colors = {
        background = "254";
        foreground = "237";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/eza/theme.yml
    assertFileContent home-files/.config/eza/theme.yml ${builtins.toFile "eza-theme-expected.yml" ''
      colors:
        background: '254'
        foreground: '237'
    ''}
  '';
}
