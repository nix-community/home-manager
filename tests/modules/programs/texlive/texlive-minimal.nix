{
  pkgs,
  config,
  ...
}:
let
  inherit (config.lib.test) mkStubPackage;

  fakeTexliveSet = {
    collection-basic = pkgs.writeTextDir "collection-basic" "";
  };
in
{
  config = {
    programs.texlive = {
      enable = true;
      extraPackages = tpkgs: { inherit (tpkgs) collection-basic; };
    };

    # Set up a minimal mocked texlive package set.
    nixpkgs.overlays = [
      (_self: _super: {
        texlive = mkStubPackage {
          name = "texlive";
          extraAttrs = {
            withPackages =
              f:
              pkgs.symlinkJoin {
                name = "dummy-texlive-combine";
                paths = f fakeTexliveSet;
              };
          };
        };
      })
    ];

    nmt.script = ''
      assertFileExists home-path/collection-basic
    '';
  };
}
