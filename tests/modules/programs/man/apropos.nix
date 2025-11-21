{
  config = {
    programs.man = {
      enable = true;
      generateCaches = true;
    };

    nmt.script = ''
      assertFileExists home-files/.manpath
      CACHE_DIR=$(cat $TESTED/home-files/.manpath | cut --delimiter=' ' --fields=3)
      assertFileExists "$CACHE_DIR/index.db"
    '';
  };
}
