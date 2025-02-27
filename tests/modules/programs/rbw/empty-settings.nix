{ pkgs, ... }:

let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  path = if isDarwin then
    "Library/Application Support/rbw/config.json"
  else
    ".config/rbw/config.json";
in {
  programs.rbw.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/${path}
  '';
}
