{ realPkgs, ... }:

{
  programs.bash.enable = true;
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  nixpkgs.overlays = [ (_: _: { inherit (realPkgs) nix-direnv; }) ];

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileExists home-files/.config/direnv/lib/hm-nix-direnv.sh
  '';
}
