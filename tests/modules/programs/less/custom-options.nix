{
  programs.less = {
    enable = true;
    options = {
      RAW-CONTROL-CHARS = true;
      quiet = true;
      wheel-lines = [
        3
        1
      ];
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/lesskey
    assertFileContent home-files/.config/lesskey ${builtins.toFile "lesskey.expected" ''
      #env
      LESS = --RAW-CONTROL-CHARS --quiet --wheel-lines 3 --wheel-lines 1
    ''}
  '';
}
