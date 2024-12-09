{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.bash.enable = true;
    programs.direnv.enable = true;
    programs.direnv.nix-direnv.enable = true;

    nmt.script = ''
      assertFileExists home-files/.bashrc
      assertFileExists home-files/.config/direnv/lib/hm-nix-direnv.sh
    '';
  };
}
