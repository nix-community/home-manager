{ config, pkgs, ... }:

let

  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  header = ''
    # Plain variables refresh on every source. Search variables add only
    # missing entries. The extra section remains once per session.
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
    export V1="v1"
    export V2="v2-v1"
    export XDG_BIN_HOME="/home/hm-user/.local/bin"
    export XDG_CACHE_HOME="/home/hm-user/.cache"
    export XDG_CONFIG_HOME="/home/hm-user/.config"
    export XDG_DATA_HOME="/home/hm-user/.local/share"
    export XDG_STATE_HOME="/home/hm-user/.local/state"
    TERMINFO_DIRS=$(
      __hm_cur="''${TERMINFO_DIRS-}"
      __hm_add=""
      __hm_entry=""
      __hm_entry="/home/hm-user/.nix-profile/share/terminfo"
      if [ -n "$__hm_entry" ]; then
        case ":$__hm_cur:$__hm_add:" in
          *":$__hm_entry:"*) ;;
          *) __hm_add="$__hm_add''${__hm_add:+:}$__hm_entry" ;;
        esac
      fi
      if [ -n "$__hm_add" ]; then
        __hm_cur="$__hm_add''${__hm_cur:+:}$__hm_cur"
      fi
      printf '%s.' "$__hm_cur"
    )
    TERMINFO_DIRS="''${TERMINFO_DIRS%?}"
    export TERMINFO_DIRS
    TERMINFO_DIRS=$(
      __hm_cur="''${TERMINFO_DIRS-}"
      __hm_add=""
      __hm_entry=""
      __hm_entry="/usr/share/terminfo"
      if [ -n "$__hm_entry" ]; then
        case ":$__hm_cur:$__hm_add:" in
          *":$__hm_entry:"*) ;;
          *) __hm_add="$__hm_add''${__hm_add:+:}$__hm_entry" ;;
        esac
      fi
      if [ -n "$__hm_add" ]; then
        __hm_cur="$__hm_cur''${__hm_cur:+:}$__hm_add"
      fi
      printf '%s.' "$__hm_cur"
    )
    TERMINFO_DIRS="''${TERMINFO_DIRS%?}"
    export TERMINFO_DIRS

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
