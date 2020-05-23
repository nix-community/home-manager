{ config, lib, ... }:

with lib;

{
  config = {
    home.file.".hidden".source = ./.hidden;

    nmt.script = ''
      assertFileExists $home_files/.hidden;
      assertFileContent $home_files/.hidden ${
        builtins.path {
          path = ./.hidden;
          name = "expected";
        }
      }
    '';
  };
}
