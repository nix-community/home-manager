{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.bash = {
      enable = true;
      historyControl = [ "erasedups" ];
      historyFile = "/home/hm-user/foo/bash/history";
    };

    nmt.script = ''
      assertFileExists home-files/.bashrc

      assertFileRegex home-files/.bashrc \
        '^mkdir -p "\$(dirname "\$HISTFILE")"'
    '';
  };
}
