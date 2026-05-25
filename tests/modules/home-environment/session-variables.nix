{ config, pkgs, ... }:

let

  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  # The variable definitions emitted after the source-guard. The expected file
  # is rebuilt from these below so the sentinel hash stays in sync with the
  # content without being hard-coded.
  linuxBody = ''
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

  darwinBody = ''
    export IS_EMPTY=""
    export IS_FALSE="false"
    export IS_TRUE="true"
    export TERMINFO_DIRS="/home/hm-user/.nix-profile/share/terminfo:$TERMINFO_DIRS''${TERMINFO_DIRS:+:}/usr/share/terminfo"
    export V1="v1"
    export V2="v2-v1"
    export XDG_BIN_HOME="/home/hm-user/.local/bin"
    export XDG_CACHE_HOME="/home/hm-user/.cache"
    export XDG_CONFIG_HOME="/home/hm-user/.config"
    export XDG_DATA_HOME="/home/hm-user/.local/share"
    export XDG_STATE_HOME="/home/hm-user/.local/state"

    # reset TERM with new TERMINFO available (if any)
    export TERM="$TERM"
  '';

  body = if isDarwin then darwinBody else linuxBody;

  # Mirrors the sentinel derivation in modules/home-environment.nix.
  sentinel = builtins.hashString "sha256" body;

  expected = pkgs.writeText "expected" (
    ''
      # Only source this once per set of variables. The sentinel changes
      # when the variables do, so updated values are picked up by the next
      # shell without requiring a full re-login.
      if [ "''${__HM_SESS_VARS_SOURCED-}" = "${sentinel}" ]; then return; fi
      export __HM_SESS_VARS_SOURCED="${sentinel}"

    ''
    + body
  );

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
