{ config, lib, pkgs, ... }:

{
  config = {
    programs.aerc = {
      enable = true;
      binds = {
        terminal = {
          "$noinherit" = true;
          "$ex" = "<C-x>";
        };
      };
      conf = {
        ui = {
          sort = "-r date";
          mouse-enabled = true;
        };
      };
      styleset = {
        "*.default" = true;
        "*.selected.reverse" = "toggle";
      };
      templates = {
        foo = ''
          bar
        '';
      };
    };

    nmt.script = let
      configDir = if pkgs.stdenv.isDarwin then
        "home-files/Library/Application Support"
      else
        "home-files/.config";
    in ''
      assertFileExists ${configDir}/aerc/aerc.conf
      assertFileExists ${configDir}/aerc/binds.conf
      assertFileExists ${configDir}/aerc/stylesets/default
      assertFileExists ${configDir}/aerc/templates/foo

      assertFileContent ${configDir}/aerc/aerc.conf ${
        builtins.toFile "aerc.conf" ''
          [ui]
          mouse-enabled=true
          sort=-r date
        ''
      }

      assertFileContent ${configDir}/aerc/binds.conf ${
        builtins.toFile "binds.conf" ''
          [terminal]
          $ex=<C-x>
          $noinherit=true
        ''
      }

      assertFileContent ${configDir}/aerc/stylesets/default ${
        builtins.toFile "default" ''
          *.default = true
          *.selected.reverse = toggle
        ''
      }

      assertFileContent ${configDir}/aerc/templates/foo ${
        builtins.toFile "foo" ''
          bar
        ''
      }
    '';
  };
}

