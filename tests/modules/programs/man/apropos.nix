{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.man = {
      enable = true;
      generateCaches = true;
    };

    nmt.script = ''
      assertFileExists home-files/.manpath

      CACHE_DIR=$(cat $TESTED/home-files/.manpath | cut --delimiter=' ' --fields=3)

      if [[ ! -f "$CACHE_DIR/index.bt" ]]; then
          fail "Expected man cache files to exist (in $CACHE_DIR) but they were not found."
      fi
    '';
  };
}
