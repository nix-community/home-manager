{ config, lib, ... }:

with lib;

{
  config = {
    programs.tmux = {
      enable = true;
    };

    nmt.script = ''
      assertFileExists home-files/.tmux.conf
    '';
  };
}
