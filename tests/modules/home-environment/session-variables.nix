{ config, pkgs, ... }:

let

  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  linuxExpected = ''
    # Only source this once.
    if [ -n "''${__HM_SESS_VARS_SOURCED-}" ]; then return; fi
    export __HM_SESS_VARS_SOURCED=1

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
  '';

  darwinExpected = ''
    # Only source this once.
    if [ -n "''${__HM_SESS_VARS_SOURCED-}" ]; then return; fi
    export __HM_SESS_VARS_SOURCED=1

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
  '';

  expected = pkgs.writeText "expected" (if isDarwin then darwinExpected else linuxExpected);

in
{
  # Keep this test to plain session variables. On Darwin the terminfo module
  # would otherwise add its TERMINFO_DIRS merge and TERM re-export here; both
  # are covered by tests/modules/targets-darwin/terminfo.nix.
  targets.darwin.terminfo.enable = false;

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
