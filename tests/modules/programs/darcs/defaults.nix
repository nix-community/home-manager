{
  programs.darcs = {
    enable = true;
    defaults = ''
      ALL ignore-times
      send sign-as AAAAAAAAAAAAAAAA
      push prehook darcs-hooks run pre-push
    '';
  };

  nmt.script = ''
    assertFileContent home-files/.darcs/defaults \
      ${builtins.toFile "expected-defaults" ''
        ALL ignore-times
        send sign-as AAAAAAAAAAAAAAAA
        push prehook darcs-hooks run pre-push
      ''}
  '';
}
