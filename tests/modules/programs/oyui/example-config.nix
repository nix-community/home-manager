{ pkgs, ... }:
let
  config = ''
    pub fn config() {
      keybind("c", global::confirm);
    }
  '';
  configDir = if pkgs.stdenv.hostPlatform.isDarwin then "Library/Application Support" else ".config";
in
{
  programs.oyui = {
    enable = true;
    package = null;
    inherit config;
  };

  nmt.script = ''
    assertFileExists 'home-files/${configDir}/oyui/config.rn'
    assertFileContent 'home-files/${configDir}/oyui/config.rn' \
      ${builtins.toFile "expected-config.rn" config}
  '';
}
