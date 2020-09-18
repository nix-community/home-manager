{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.kakoune = { enable = true; };

    nmt.script = ''
      assertFileNotRegex home-path/share/kak/plugins.kak . # file is empty
    '';
  };
}
