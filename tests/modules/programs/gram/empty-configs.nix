{ pkgs, ... }:

let
  inherit (pkgs) stdenv;

  dataDir =
    "home-files/"
    + (if stdenv.isDarwin then "Library/Application Support/Gram" else ".local/share/gram");
in

{
  programs.gram.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.config/gram
    assertPathNotExists '${dataDir}'
  '';
}
