{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.kakoune = {
      enable = true;
      plugins = [ pkgs.kakounePlugins.kak-powerline ];
    };

    nmt.script = ''
      assertDirectoryNotEmpty home-path/share/kak/autoload/plugins
    '';
  };
}
