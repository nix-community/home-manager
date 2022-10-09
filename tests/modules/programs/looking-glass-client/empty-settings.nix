{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.looking-glass-client = {
      enable = true;
      package = config.lib.test.mkStubPackage { };
    };

    nmt.script = ''
      assertPathNotExists home-files/.config/looking-glass/client.ini
    '';
  };
}
