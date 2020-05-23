{ config, lib, ... }:

with lib;

{
  config = {
    programs.tmux = { enable = false; };

    nmt.script = ''
      assertPathNotExists $home_files/.tmux.conf
    '';
  };
}
