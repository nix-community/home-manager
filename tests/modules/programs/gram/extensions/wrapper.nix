{ pkgs, ... }:

let
  inherit (pkgs) writeScriptBin writeTextDir;
in

{
  programs.gram = {
    enable = true;
    package = writeScriptBin "gram" "";
    extensionPackages = [
      (writeTextDir "share/gram/extensions/foo/.keep" "")
      (writeTextDir "share/zed/extensions/bar/.keep" "")
    ];
  };

  nmt.script = ''
    assertFileContains home-path/bin/gram \
      'export GRAM_SYSTEM_EXTENSIONS_DIR'
  '';
}
