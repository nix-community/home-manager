{ pkgs, ... }:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  path = if isDarwin then
    "Library/Application Support/rbw/config.json"
  else
    ".config/rbw/config.json";
in {
  config = {
    programs.rbw.enable = true;

    nixpkgs.overlays = [ (import ./overlay.nix) ];

    nmt.script = ''
      assertPathNotExists home-files/${path}
    '';
  };
}
