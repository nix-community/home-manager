{ config, lib, ... }:

with lib;

{
  config = {
    programs.texlive.enable = true;

    nmt.script = ''
      assertFileExists $home_path/bin/tex
    '';
  };
}
