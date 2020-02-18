{ config, lib, ... }:

with lib;

{
  config = {
    programs.texlive.enable = true;

    nmt.script = ''
      assertFileExists home-path/bin/tex
    '';
  };
}
