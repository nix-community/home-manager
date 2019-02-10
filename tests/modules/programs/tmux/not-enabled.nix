{ config, lib, ... }:

with lib;

{
  config = {
    programs.tmux = { enable = false; };

    nmt.script = ''
      assertFileNotExists home-files/.tmux.conf
    '';
  };
}
