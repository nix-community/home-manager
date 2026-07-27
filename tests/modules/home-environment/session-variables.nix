{ config, pkgs, ... }:

let

  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  header = ''
    # This file is safe to source multiple times: session variables are
    # plain assignments and search variables (PATH and friends) only
    # add non-empty entries that are not already present, prepending or
    # appending them, so re-sourcing introduces no new duplicates and
    # never reorders entries added by other tools. Only the extra
    # section at the end, which may contain non-idempotent commands,
    # runs once per session.
  '';

  linuxExpected = header + ''

    export IS_EMPTY=""
    export IS_FALSE="false"
    export IS_TRUE="true"
    export LOCALE_ARCHIVE_2_27="${config.i18n.glibcLocales}/lib/locale/locale-archive"
    export V1="v1"
    export V2="v2-v1"
    export XDG_BIN_HOME="/home/hm-user/.local/bin"
    export XDG_CACHE_HOME="/home/hm-user/.cache"
    export XDG_CONFIG_HOME="/home/hm-user/.config"
    export XDG_DATA_HOME="/home/hm-user/.local/share"
    export XDG_STATE_HOME="/home/hm-user/.local/state"

    if [ -z "''${__HM_SESS_VARS_SOURCED-}" ]; then
    export __HM_SESS_VARS_SOURCED=1

    fi
  '';

  darwinExpected = header + ''

    export IS_EMPTY=""
    export IS_FALSE="false"
    export IS_TRUE="true"
    export TERMINFO_DIRS="/home/hm-user/.nix-profile/share/terminfo:/usr/share/terminfo"
    export V1="v1"
    export V2="v2-v1"
    export XDG_BIN_HOME="/home/hm-user/.local/bin"
    export XDG_CACHE_HOME="/home/hm-user/.cache"
    export XDG_CONFIG_HOME="/home/hm-user/.config"
    export XDG_DATA_HOME="/home/hm-user/.local/share"
    export XDG_STATE_HOME="/home/hm-user/.local/state"

    if [ -z "''${__HM_SESS_VARS_SOURCED-}" ]; then
    export __HM_SESS_VARS_SOURCED=1
    # reset TERM with new TERMINFO available (if any)
    export TERM="$TERM"

    fi
  '';

  expected = pkgs.writeText "expected" (if isDarwin then darwinExpected else linuxExpected);

in
{
  home.sessionVariables = {
    V1 = "v1";
    V2 = "v2-${config.home.sessionVariables.V1}";
    IS_EMPTY = "";
    IS_NULL = null;
    IS_TRUE = true;
    IS_FALSE = false;
  };

  nmt.script = ''
    assertFileExists home-path/etc/profile.d/hm-session-vars.sh
    assertFileContent home-path/etc/profile.d/hm-session-vars.sh \
      ${expected}
  '';
}
