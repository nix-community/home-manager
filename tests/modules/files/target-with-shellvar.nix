{ ... }:

{
  home.file."$HOME/$FOO/bar baz".text = "blah";

  nmt.script = ''
    assertFileExists 'home-files/$HOME/$FOO/bar baz';
    assertFileContent 'home-files/$HOME/$FOO/bar baz' \
      ${builtins.toFile "expected" "blah"}
  '';
}
