{ config, lib, pkgs, ... }:

let

  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  linuxExpected = ''
    # Only source this once.
    if [ -n "$__HM_SESS_VARS_SOURCED" ]; then return; fi
    export __HM_SESS_VARS_SOURCED=1

    export LOCALE_ARCHIVE_2_27="${pkgs.glibcLocales}/lib/locale/locale-archive"
    export V1="v1"
    export V2="v2-v1"
    export XDG_CACHE_HOME="/home/hm-user/.cache"
    export XDG_CONFIG_HOME="/home/hm-user/.config"
    export XDG_DATA_HOME="/home/hm-user/.local/share"
    export XDG_STATE_HOME="/home/hm-user/.local/state"
  '';

  darwinExpected = ''
    # Only source this once.
    if [ -n "$__HM_SESS_VARS_SOURCED" ]; then return; fi
    export __HM_SESS_VARS_SOURCED=1

    export V1="v1"
    export V2="v2-v1"
    export XDG_CACHE_HOME="/home/hm-user/.cache"
    export XDG_CONFIG_HOME="/home/hm-user/.config"
    export XDG_DATA_HOME="/home/hm-user/.local/share"
    export XDG_STATE_HOME="/home/hm-user/.local/state"
  '';

  expected = pkgs.writeText "expected" (if isDarwin then darwinExpected else linuxExpected);

in {
  config = {
    home.sessionVariables = {
      V1 = "v1";
      V2 = "v2-${config.home.sessionVariables.V1}";
    };

    nmt.script = ''
      assertFileExists home-path/etc/profile.d/hm-session-vars.sh
      assertFileContent home-path/etc/profile.d/hm-session-vars.sh \
        ${expected}
    '';
  };
}
