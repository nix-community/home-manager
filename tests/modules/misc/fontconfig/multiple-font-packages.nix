{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    home.packages = [ pkgs.comic-relief pkgs.unifont ];

    fonts.fontconfig.enable = true;

    nmt.script = ''
      assertDirectoryNotEmpty $home_path/lib/fontconfig/cache
    '';
  };
}
