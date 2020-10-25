{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.zsh.prezto.enable = true;

    nmt.script = ''
      assertFileExists home-files/.zpreztorc
    '';
  };
}
