{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.bash.enable = true;
    programs.direnv.enable = true;

    nmt.script = ''
      assertFileExists home-files/.bashrc
      assertFileRegex \
        home-files/.bashrc \
        'eval "\$(/nix/store/.*direnv.*/bin/direnv hook bash)"'
    '';
  };
}
