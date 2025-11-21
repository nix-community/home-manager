{ lib, pkgs, ... }:
{
  config = {
    programs.texlive.enable = true;

    # Set up a minimal mocked texlive package set.
    nixpkgs.overlays = [
      (self: super: {
        texlive = {
          collection-basic = pkgs.writeTextDir "collection-basic" "";
          combine =
            tpkgs:
            pkgs.symlinkJoin {
              name = "dummy-texlive-combine";
              paths = lib.attrValues tpkgs;
            };
        };
      })
    ];

    nmt.script = ''
      assertFileExists home-path/collection-basic
    '';
  };
}
