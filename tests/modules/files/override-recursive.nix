{ pkgs, ... }:

{
  home.file = {
    "foo" = {
      source = pkgs.runCommand "foo-recursive" { } ''
        mkdir $out
        echo -n foo > $out/foo
        echo -n bar > $out/bar
        echo -n baz > $out/baz
      '';
      recursive = true;
    };
    "foo/bar".text = "bar override";
    "blah" = {
      text = "baz override";
      target = "foo/baz";
    };
  };

  nmt.script = ''
    assertFileExists 'home-files/foo/foo';
    assertFileContent 'home-files/foo/foo' \
      ${builtins.toFile "foo-expected" "foo"}

    assertFileExists 'home-files/foo/bar';
    assertFileContent 'home-files/foo/bar' \
      ${builtins.toFile "bar-expected" "bar override"}

    assertFileExists 'home-files/foo/baz';
    assertFileContent 'home-files/foo/baz' \
      ${builtins.toFile "baz-expected" "baz override"}
  '';
}
