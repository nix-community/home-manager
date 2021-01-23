{ config, lib, pkgs, ... }:

let inherit (pkgs.stdenv.hostPlatform) isLinux;
in {
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
          ${lib.optionalString isLinux ''

            export LOCALE_ARCHIVE_2_27="${pkgs.glibcLocales}/lib/locale/locale-archive"''}
          export XDG_CACHE_HOME="/home/hm-user/.cache"
          export XDG_CONFIG_HOME="/home/hm-user/.config"
          export XDG_DATA_HOME="/home/hm-user/.local/share"
          export PATH="$PATH''${PATH:+:}bar:baz:foo"
        ''
      }
  '';

}
