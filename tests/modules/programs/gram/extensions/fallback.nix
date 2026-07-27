{ pkgs, ... }:

let
  inherit (pkgs) writeTextDir;
in

{
  programs.gram = {
    enable = true;
    package = null;
    extensionPackages = [
      (writeTextDir "share/gram/extensions/foo/.keep" "")
      (writeTextDir "share/zed/extensions/bar/.keep" "")
    ];
  };

  nmt.script = ''
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
      'export GRAM_SYSTEM_EXTENSIONS_DIR'
  '';
}
