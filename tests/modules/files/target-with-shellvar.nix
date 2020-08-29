{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    home.file."$HOME/$FOO/bar baz".text = "blah";

    nmt.script = ''
      assertFileExists 'home-files/$HOME/$FOO/bar baz';
      assertFileContent 'home-files/$HOME/$FOO/bar baz' \
        ${pkgs.writeText "expected" "blah"}
    '';
  };
}
