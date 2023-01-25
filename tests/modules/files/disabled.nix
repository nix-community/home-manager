{ config, lib, ... }:

with lib;

{
  config = {
    home.file."disabled" = {
      text = ''
        This file should not exist
      '';
      enable = false;
    };
    nmt.script = ''
      assertPathNotExists home-files/disabled
    '';
  };
}
