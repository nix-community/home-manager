{
  debug = { pkgs, config, lib, ... }: {
    home.enableDebugInfo = true;
    home.packages = with pkgs; [ curl gdb ];

    nmt.script = ''
      [ -L $TESTED/$home_path/lib/debug/curl ] \
        || fail "Debug-symbols for pkgs.curl should exist in \`/$home_path/lib/debug'!"

      #source $TESTED/$home_path/etc/profile.d/hm-session-vars.sh
      #[[ "$NIX_DEBUG_INFO_DIRS" =~ /lib/debug$ ]] \
        #|| fail "Invalid NIX_DEBUG_INFO_DIRS!"
      assertFileExists $home_path/etc/profile.d/hm-session-vars.sh
      assertFileRegex $home_path/etc/profile.d/hm-session-vars.sh \
          'NIX_DEBUG_INFO_DIRS=.*/lib/debug'

      # We need to override NIX_DEBUG_INFO_DIRS here as $HOME evalutes to the home
      # of the user who executes this testcase :/
      { echo quit | PATH="$TESTED/$home_path/bin''${PATH:+:}$PATH" NIX_DEBUG_INFO_DIRS=$TESTED/$home_path/lib/debug \
        gdb curl 2>&1 | \
        grep 'Reading symbols from ${builtins.storeDir}/'; \
      } || fail "Failed to read debug symbols from curl in gdb"
    '';
  };
}
