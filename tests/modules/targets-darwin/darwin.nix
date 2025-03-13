{ pkgs, ... }:
let
  darwinTestApp = pkgs.runCommandLocal "target-darwin-example-app" { } ''
    mkdir -p $out/Applications
    touch $out/Applications/example-app
  '';
in {
  config = {
    home.packages = [ darwinTestApp ];

    nmt.script = ''
      assertFileExists 'home-files/Applications/Home Manager Apps/example-app'
    '';
  };
}
