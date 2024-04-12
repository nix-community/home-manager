{ lib, ... }:

with lib;

{
  config = {
    programs.zsh = {
      enable = true;

      localVariables = rec {
        V1 = true;
        V2 = false;
        V3 = "some-string";
        V4 = 42;
        V5 = [ V1 V2 V3 V4 ];
      };
    };

    test.stubs.zsh = { };

    nmt.script = ''
      assertFileExists home-files/.zshrc
      assertFileContains home-files/.zshrc 'V1=true'
      assertFileContains home-files/.zshrc 'V2=false'
      assertFileContains home-files/.zshrc 'V3="some-string"'
      assertFileContains home-files/.zshrc 'V4="42"'
      assertFileContains home-files/.zshrc 'V5=(true false "some-string" "42")'
      '';
  };
}
