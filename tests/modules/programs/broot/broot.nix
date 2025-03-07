{ realPkgs, ... }:

{
  programs.broot = {
    enable = true;
    settings.modal = true;
  };

  nixpkgs.overlays = [ (self: super: { inherit (realPkgs) broot hjson-go; }) ];

  nmt.script = ''
    assertFileExists home-files/.config/broot/conf.toml
    assertFileContains home-files/.config/broot/conf.toml 'modal = true'
  '';
}
