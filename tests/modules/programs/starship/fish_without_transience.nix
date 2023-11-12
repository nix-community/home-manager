{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs = {
      fish.enable = true;
      starship.enable = true;
    };

    nmt.script = ''
      assertFileExists home-files/.config/fish/config.fish
      assertFileNotRegex home-files/.config/fish/config.fish 'enable_transience'
    '';
  };
}
