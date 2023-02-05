{ config, pkgs, ... }:

let

  expectedFunc = pkgs.writeText "func.fish" ''
    function func
        echo foo
    end
  '';

  expectedFuncMulti = pkgs.writeText "func-multi.fish" ''
    function func-multi
        echo bar
        if foo
            bar
            baz
        end
    end
  '';

in {
  config = {
    programs.fish = {
      enable = true;

      formatFishScripts = true;

      functions = {
        func = ''echo "foo"'';
        func-multi = ''
              echo bar
          if foo
              bar
                  baz
                end
        '';
      };
    };

    nmt.script = ''
      assertFileExists home-files/.config/fish/functions/func.fish
      echo ${expectedFunc}
      assertFileContent home-files/.config/fish/functions/func.fish ${expectedFunc}

      assertFileExists home-files/.config/fish/functions/func-multi.fish
      echo ${expectedFuncMulti}
      assertFileContent home-files/.config/fish/functions/func-multi.fish ${expectedFuncMulti}
    '';
  };
}
