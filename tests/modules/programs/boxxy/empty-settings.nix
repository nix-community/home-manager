{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.boxxy.enable = true;

    test.stubs.boxxy = { };

    nmt.script = ''
      assertPathNotExists home-files/.config/boxxy
    '';
  };
}
