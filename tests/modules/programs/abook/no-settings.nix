{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.abook.enable = true;

    test.stubs.abook = { };

    nmt.script = ''
      assertPathNotExists home-files/.config/abook/abookrc
    '';
  };
}
