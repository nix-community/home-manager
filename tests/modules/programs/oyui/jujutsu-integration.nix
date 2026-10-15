{ pkgs, ... }:
let
  configDir = if pkgs.stdenv.hostPlatform.isDarwin then "Library/Application Support" else ".config";
in
{
  programs = {
    jujutsu = {
      enable = true;
      package = null;
    };
    oyui = {
      enable = true;
      package = null;
      enableJujutsuIntegration = true;
    };
  };

  nmt.script = ''
    assertFileExists home-files/${configDir}/jj/config.toml
    assertFileContains home-files/${configDir}/jj/config.toml 'diff-editor = "oyui"'
    assertFileContains home-files/${configDir}/jj/config.toml '[merge-tools.oyui]'
    assertFileContains home-files/${configDir}/jj/config.toml 'program = "oyui"'
  '';
}
