{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ ./stubs.nix ];

  programs.kakoune = { enable = true; };

  nmt.script = ''
    assertPathNotExists home-path/share/kak/autoload/plugins
  '';
}
