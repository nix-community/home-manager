{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.kakoune = { enable = true; };

    nmt.script = ''
      assertPathNotExists home-path/share/kak/autoload/plugins
    '';
  };
}
