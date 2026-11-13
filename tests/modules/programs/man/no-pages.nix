{
  config = {
    programs.man = {
      enable = true;
      generateCaches = true;
    };

    test.stubs.man.buildScript = ''
      mkdir -p $out/bin
      printf '#!/bin/sh\n' > $out/bin/mandb
      chmod 755 $out/bin/mandb
    '';

    nmt.script = ''
      assertFileExists home-files/.manpath
      CACHE_DIR=$(cat $TESTED/home-files/.manpath | cut --delimiter=' ' --fields=3)
      assertDirectoryExists "$CACHE_DIR"
    '';
  };
}
