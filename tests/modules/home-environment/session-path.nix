{ config, lib, pkgs, ... }:

{
  imports = [
    ({ ... }: { config.home.sessionPath = [ "foo" ]; })
    ({ ... }: { config.home.sessionPath = [ "bar" "baz" ]; })
  ];

  nmt.script = ''
    assertFileExists home-path/etc/profile.d/hm-session-vars.sh
    assertFileContent \
      home-path/etc/profile.d/hm-session-vars.sh \
      ${
        pkgs.writeText "session-path-expected.txt" ''
          # Only source this once.
          if [ -n "$__HM_SESS_VARS_SOURCED" ]; then return; fi
          export __HM_SESS_VARS_SOURCED=1

          export XDG_CACHE_HOME="/home/hm-user/.cache"
          export XDG_CONFIG_HOME="/home/hm-user/.config"
          export XDG_DATA_HOME="/home/hm-user/.local/share"
          export PATH="$PATH''${PATH:+:}bar:baz:foo"
        ''
      }
  '';

}
