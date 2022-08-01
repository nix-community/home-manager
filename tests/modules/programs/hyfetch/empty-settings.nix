{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.hyfetch.enable = true;

    test.stubs.hyfetch = { };

    nmt.script = ''
      assertPathNotExists home-files/.config/hyfetch.json
    '';
  };
}
