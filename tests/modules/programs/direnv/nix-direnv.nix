{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.bash.enable = true;
    programs.direnv.enable = true;
    programs.direnv.enableNixDirenvIntegration = true;

    nmt.script = ''
      assertFileExists home-files/.bashrc
      assertFileRegex \
        home-files/.config/direnv/direnvrc \
        'source /nix/store/.*nix-direnv.*/share/nix-direnv/direnvrc'
    '';
  };
}
