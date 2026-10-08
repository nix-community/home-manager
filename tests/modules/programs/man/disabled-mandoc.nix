{
  config = {
    programs.man = {
      enable = false;
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

      assertPathNotExists home-files/.manpath
      assertPathNotExists home-files/.local/share/mandoc/man

      assertFileExists "$hmSessVars"
      assertFileNotRegex "$hmSessVars" 'MANPATH='
    '';
  };
}
