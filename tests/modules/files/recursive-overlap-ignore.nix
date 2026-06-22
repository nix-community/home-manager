{ pkgs, ... }:

{
  home.fileOverlapResolution = "ignore";
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
    "foo/bar".text = "bar ignore";
    "blah" = {
      text = "baz ignore";
      target = "foo/baz";
    };
  };

  nmt.script = ''
    assertFileExists 'home-files/foo/foo';
    assertFileContent 'home-files/foo/foo' \
      ${builtins.toFile "foo-expected" "foo"}

    assertFileExists 'home-files/foo/bar';
    assertFileContent 'home-files/foo/bar' \
      ${builtins.toFile "bar-expected" "bar"}

    assertFileExists 'home-files/foo/baz';
    assertFileContent 'home-files/foo/baz' \
      ${builtins.toFile "baz-expected" "baz"}
  '';
}
