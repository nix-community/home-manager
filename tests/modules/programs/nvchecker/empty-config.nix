{ pkgs, ... }:
let
  configDir =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/nvchecker"
    else
      ".config/nvchecker";
in
{
  programs.nvchecker.enable = true;

  nmt.script = ''
    assertFileExists "home-files/${configDir}/nvchecker.toml"
    assertFileContent "home-files/${configDir}/nvchecker.toml" "${./empty-config.toml}"
  '';
}
