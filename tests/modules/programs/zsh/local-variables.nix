{ lib, ... }:

{
  config = {
    programs.zsh = {
      enable = true;

      localVariables = rec {
        V1 = true;
        V2 = false;
        V3 = "some-string";
        V4 = 42;
        V5 = [
          V1
          V2
          V3
          V4
        ];
      };
    };

    test.stubs.zsh = { };

    nmt.script = ''
      assertFileExists home-files/.zshrc
      assertFileRegex home-files/.zshrc '^V1=true$'
      assertFileRegex home-files/.zshrc '^V2=false$'
      assertFileRegex home-files/.zshrc '^V3="some-string"$'
      assertFileRegex home-files/.zshrc '^V4="42"$'
      assertFileRegex home-files/.zshrc '^V5=[(]'
    '';
  };
}
