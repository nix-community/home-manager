{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    home.packages = [
      # Look, no font!
    ];

    fonts.fontconfig.enable = true;

    nmt.script = ''
      assertPathNotExists $home_path/lib/fontconfig/cache
    '';
  };
}
