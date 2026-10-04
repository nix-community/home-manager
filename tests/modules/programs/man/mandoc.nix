{
  config = {
    programs.man = {
      enable = true;
      man-db.enable = false;
      mandoc.enable = true;
      generateCaches = true;
    };

    test.stubs = {
      mandoc = {
        outPath = null;
        buildScript = ''
          mkdir -p $out/bin
          touch $out/bin/{man,makewhatis}
          chmod +x $out/bin/*
        '';
      };
    };

    nmt.script = ''
      hmSessVars=home-path/etc/profile.d/hm-session-vars.sh

      assertLinkExists home-files/.local/share/mandoc/man

      assertFileExists $hmSessVars
      (
        export MANPATH=/inherited/man
        unset __HM_SESS_VARS_SOURCED __HM_SESS_VARS_MERGED
        . "$TESTED/$hmSessVars"
        [ "$MANPATH" = "/home/hm-user/.local/share/mandoc/man:/inherited/man" ] \
          || { echo "MANPATH: $MANPATH"; exit 1; }
      ) || fail "mandoc man directory was not prepended to MANPATH"
    '';
  };
}
