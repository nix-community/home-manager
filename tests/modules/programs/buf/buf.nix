{ config, lib, pkgs, ... }:

{
  config = {
    programs.buf = {
      enable = true;
    };

    nmt.script = ''
      assertFileExists home-path/bin/buf
    '';
  };
}
