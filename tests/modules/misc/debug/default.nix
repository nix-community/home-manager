{
  debug =
    {
      realPkgs,
      config,
      lib,
      ...
    }:
    lib.mkIf config.test.enableBig {
      home.enableDebugInfo = true;
      home.packages = with realPkgs; [
        curl
        gdb
      ];

      nmt.script = ''
        [ -L $TESTED/home-path/lib/debug/curl ] \
          || fail "Debug-symbols for pkgs.curl should exist in \`/home-path/lib/debug'!"

        assertFileExists home-path/etc/profile.d/hm-session-vars.sh
        (
          export NIX_DEBUG_INFO_DIRS=/inherited/debug
          unset __HM_SESS_VARS_SOURCED __HM_SESS_VARS_MERGED
          . "$TESTED/home-path/etc/profile.d/hm-session-vars.sh"
          case "$NIX_DEBUG_INFO_DIRS" in
            */lib/debug:/inherited/debug) ;;
            *) echo "NIX_DEBUG_INFO_DIRS: $NIX_DEBUG_INFO_DIRS"; exit 1 ;;
          esac
        ) || fail "Invalid NIX_DEBUG_INFO_DIRS!"

        # We need to override NIX_DEBUG_INFO_DIRS here as $HOME evaluates to the home
        # of the user who executes this testcase :/
        { echo quit | PATH="$TESTED/home-path/bin''${PATH:+:}$PATH" NIX_DEBUG_INFO_DIRS=$TESTED/home-path/lib/debug \
          gdb curl 2>&1 | \
          grep 'Reading symbols from ${builtins.storeDir}/'; \
        } || fail "Failed to read debug symbols from curl in gdb"
      '';
    };
}
