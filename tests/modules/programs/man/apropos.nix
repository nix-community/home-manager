{ realPkgs, ... }:

{
  config = {
    # The cache index is built from manual pages of installed packages, so the
    # package that provides them has to be real.
    test.unstubs = [ (_self: _super: { inherit (realPkgs) man; }) ];

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
