{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.tmux = {
      enable = true;
      secureSocket = true;
    };

    nmt.script = ''
      assertFileExists $home_path/etc/profile.d/hm-session-vars.sh
      assertFileContains $home_path/etc/profile.d/hm-session-vars.sh \
        'export TMUX_TMPDIR="''${XDG_RUNTIME_DIR:-"/run/user/\$(id -u)"}"'
    '';
  };
}
