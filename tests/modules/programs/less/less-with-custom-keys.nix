{
  programs.less = {
    enable = true;

    keys = ''
      s        back-line
      t        forw-line
    '';
  };

  nmt.script = ''
    assertFileExists home-files/.config/lesskey
    assertFileContent home-files/.config/lesskey ${
      builtins.toFile "less.expected" ''
        s        back-line
        t        forw-line
      ''
    }
  '';
}
