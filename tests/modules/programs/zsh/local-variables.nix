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
        V5 = builtins.attrValues V6;
        V6 = {
          a = V1;
          b = V2;
          c = V3;
          d = V4;
        };
      };
    };

    test.stubs.zsh = { };

    nmt.script = ''
      assertFileExists home-files/.zshrc
      assertFileRegex home-files/.zshrc '^V1=true$'
      assertFileRegex home-files/.zshrc '^V2=false$'
      assertFileRegex home-files/.zshrc '^V3="some-string"$'
      assertFileRegex home-files/.zshrc '^V4="42"$'
      assertFileRegex home-files/.zshrc '^V5=[(]true false "some-string" "42"[)]$'
      assertFileContains home-files/.zshrc ${
        lib.escapeShellArg ''
          typeset -A V6=(['a']=true ['b']=false ['c']="some-string" ['d']="42")''
      }
    '';
  };
}
