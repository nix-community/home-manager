{ config, lib, ... }:

with lib;

{
  config = {
    programs.man = { enable = true; };

    nmt.script = ''
      assertPathNotExists home-files/.manpath
    '';
  };
}
