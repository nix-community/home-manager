let
  config = ''
    #command
    s        back-line
    t        forw-line
  '';
in
{
  programs.less = {
    enable = true;
    inherit config;
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
    assertFileContent home-files/.config/lesskey ${builtins.toFile "less.expected" ''
      #env
      LESS = --RAW-CONTROL-CHARS --quiet --wheel-lines 3 --wheel-lines 1

      ${config}''}
  '';
}
