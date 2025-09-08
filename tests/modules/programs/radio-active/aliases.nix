{
  programs.radio-active = {
    enable = true;

    aliases = {
      "Deep House Lounge" = "http://198.15.94.34:8006/stream";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.radio-active-alias
    assertFileContent home-files/.radio-active-alias \
    ${builtins.toFile "expected.radio-active_aliases.ini" ''
      Deep House Lounge==http://198.15.94.34:8006/stream
    ''}
  '';
}
