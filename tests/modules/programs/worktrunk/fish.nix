{
  config,
  lib,
  realPkgs,
  ...
}:

lib.mkIf config.test.enableBig {
  programs = {
    worktrunk.enable = true;
    fish.enable = true;
  };

  nixpkgs.overlays = [ (_self: _super: { inherit (realPkgs) worktrunk; }) ];

  nmt.script = ''
    assertFileExists home-files/.config/fish/config.fish
    assertFileRegex home-files/.config/fish/config.fish \
      '/nix/store/.*worktrunk.*/bin/wt config shell init fish \| source'
  '';
}
