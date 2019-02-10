{ config, lib, ... }:

with lib;

{
  config = {
    programs.tmux = { enable = false; };

    nmt.script = ''
      !assertFileExists home-files/.tmux.conf
    '';
  };
}
