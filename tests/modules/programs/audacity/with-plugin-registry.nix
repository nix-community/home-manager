{ pkgs, ... }:
let
  configDir =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "home-files/Library/Application Support/audacity"
    else
      "home-files/.config/audacity";
in
{
  programs.audacity = {
    enable = true;
    pluginRegistry = {
      MyPlugin = {
        effectFamily = "1";
        enabled = "1";
      };
    };
  };

  nmt.script = ''
    registryFile="${configDir}/pluginregistry.cfg"
    assertFileExists "$registryFile"
    assertFileContent "$registryFile" ${builtins.toFile "expected" ''
      [MyPlugin]
      effectFamily=1
      enabled=1
    ''}
  '';
}
