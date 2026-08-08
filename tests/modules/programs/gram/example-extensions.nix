{ pkgs, ... }:

let
  inherit (pkgs) stdenv writeTextDir;

  dataDir =
    "home-files/"
    + (if stdenv.isDarwin then "Library/Application Support/Gram" else ".local/share/gram");
in

{
  programs.gram = {
    enable = true;
    extensionPackages = [
      (writeTextDir "share/gram/extensions/foo/.keep" "")
      (writeTextDir "share/zed/extensions/bar/.keep" "")
    ];
  };

  nmt.script = ''
    extensionDir='${dataDir}/extensions/installed'

    assertDirectoryExists "$extensionDir"/foo
    assertDirectoryExists "$extensionDir"/bar
  '';
}
