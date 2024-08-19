{ config, lib, ... }:

with lib;

{
  config = {
    programs.htop.enable = true;

    test.stubs.htop = { };

    nmt.script = ''
      assertPathNotExists home-files/.config/htop
    '';
  };
}
