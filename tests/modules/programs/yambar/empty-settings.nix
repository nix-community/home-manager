{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.yambar.enable = true;

    test.stubs.yambar = { };

    nmt.script = ''
      assertPathNotExists home-files/.config/yambar
    '';
  };
}
