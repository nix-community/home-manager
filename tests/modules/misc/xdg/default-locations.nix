{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    # Test fallback behavior for stateVersion >= 20.09, which is pure.
    xdg.enable = lib.mkForce false;
    home.stateVersion = "20.09";

    xdg.configFile.test.text = "config";
    xdg.dataFile.test.text = "data";
    home.file."${config.xdg.cacheHome}/test".text = "cache";
    home.file."${config.xdg.stateHome}/test".text = "state";

    nmt.script = ''
      assertFileExists home-files/.config/test
      assertFileExists home-files/.local/share/test
      assertFileExists home-files/.cache/test
      assertFileExists home-files/.local/state/test
      assertFileContent \
        home-files/.config/test \
        ${builtins.toFile "test" "config"}
      assertFileContent \
        home-files/.local/share/test \
        ${builtins.toFile "test" "data"}
      assertFileContent \
        home-files/.cache/test \
        ${builtins.toFile "test" "cache"}
      assertFileContent \
        home-files/.local/state/test \
        ${builtins.toFile "test" "state"}
    '';
  };
}
