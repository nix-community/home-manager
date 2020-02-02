{ config, lib, ... }:

with lib;

{
  config = {
    home.file.".hidden".source = ./.hidden;

    nmt.script = ''
      assertFileExists home-files/.hidden;
      assertFileContent home-files/.hidden ${
        builtins.path {
          path = ./.hidden;
          name = "expected";
        }
      }
    '';
  };
}
