{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.foot.enable = true;

    test.stubs.foot = { };

    nmt.script = ''
      assertPathNotExists home-files/.config/foot
    '';
  };
}
