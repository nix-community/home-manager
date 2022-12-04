{ config, lib, pkgs, ... }:

with lib;

let
  preLoad = builtins.toFile "preLoad" ''
    #!/bin/sh
    echo preLoad
  '';
  postLoad = builtins.toFile "postLoad" ''
    #!/bin/sh
    echo postLoad
  '';
  preSave = builtins.toFile "preSave" ''
    #!/bin/sh
    echo preSave
  '';
  postSave = builtins.toFile "postSave" ''
    #!/bin/sh
    echo postSave
  '';
in {
  config = {
    programs.calcurse = {
      enable = true;

      hooks = {
        preLoad = ''
          #!/bin/sh
          echo preLoad
        '';

        postLoad = ''
          #!/bin/sh
          echo postLoad
        '';

        preSave = ''
          #!/bin/sh
          echo preSave
        '';

        postSave = ''
          #!/bin/sh
          echo postSave
        '';
      };
    };

    test.stubs.calcurse = { };

    nmt.script = ''
      assertFileExists home-files/.config/calcurse/hooks/pre-load
      assertFileContent home-files/.config/calcurse/hooks/pre-load ${preLoad}

      assertFileExists home-files/.config/calcurse/hooks/post-load
      assertFileContent home-files/.config/calcurse/hooks/post-load ${postLoad}

      assertFileExists home-files/.config/calcurse/hooks/pre-save
      assertFileContent home-files/.config/calcurse/hooks/pre-save ${preSave}

      assertFileExists home-files/.config/calcurse/hooks/post-save
      assertFileContent home-files/.config/calcurse/hooks/post-save ${postSave}
    '';
  };
}
