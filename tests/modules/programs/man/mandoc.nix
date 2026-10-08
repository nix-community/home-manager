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
      assertFileContains $hmSessVars \
        'export MANPATH="/home/hm-user/.local/share/mandoc/man''${MANPATH:+:}$MANPATH"'
    '';
  };
}
