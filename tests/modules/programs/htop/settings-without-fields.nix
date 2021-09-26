{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.htop.enable = true;
    programs.htop.settings = { color_scheme = 6; };

    test.stubs.htop = { };

    # Test that the 'fields' key is written in addition to the customized
    # settings or htop won't read the options.
    nmt.script = ''
      htoprc=home-files/.config/htop/htoprc
      assertFileExists $htoprc
      assertFileContent $htoprc \
        ${
          builtins.toFile "htoprc-expected" ''
            color_scheme=6
            fields=0 48 17 18 38 39 40 2 46 47 49 1
          ''
        }
    '';
  };

}
