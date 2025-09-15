{ pkgs, ... }:
let
  configDir =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/nvchecker"
    else
      ".config/nvchecker";
in
{
  programs.nvchecker = {
    enable = true;
    settings = {
      __config__ = {
        keyfile = "keyfile.toml";
      };
      nvchecker = {
        source = "github";
        github = "lilydjwg/nvchecker";
      };
    };
  };

  nmt.script = ''
    assertFileExists "home-files/${configDir}/nvchecker.toml"
    assertFileContent "home-files/${configDir}/nvchecker.toml" "${./basic-config.toml}"
  '';
}
