{ realPkgs, ... }:

{
  programs.broot = {
    enable = true;
    settings.modal = true;
  };

  nixpkgs.overlays = [ (self: super: { inherit (realPkgs) broot hjson-go; }) ];

  nmt.script = ''
    assertFileExists home-files/.config/broot/conf.hjson
    assertFileContains home-files/.config/broot/conf.hjson '"modal": true'
  '';
}
