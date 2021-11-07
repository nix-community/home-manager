{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ ./stubs.nix ];

  programs.kakoune = {
    enable = true;
    plugins = [ pkgs.kakounePlugins.prelude-kak ];
  };

  nmt.script = ''
    assertDirectoryNotEmpty home-path/share/kak/autoload/plugins
  '';
}
