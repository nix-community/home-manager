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
  };

  nmt.script = ''
    assertFileExists home-files/.config/lesskey
    assertFileContent home-files/.config/lesskey ${builtins.toFile "less.expected" config}
  '';
}
