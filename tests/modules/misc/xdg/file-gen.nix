{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    xdg.configHome = /. + "${config.home.homeDirectory}/.dummy-config";
    xdg.dataHome = /. + "${config.home.homeDirectory}/.dummy-data";
    xdg.cacheHome = /. + "${config.home.homeDirectory}/.dummy-cache";

    xdg.configFile.test.text = "config";
    xdg.dataFile.test.text = "data";
    home.file."${config.xdg.cacheHome}/test".text = "cache";

    nmt.script = ''
      assertFileExists home-files/.dummy-config/test
      assertFileExists home-files/.dummy-cache/test
      assertFileExists home-files/.dummy-data/test
      assertFileContent \
        home-files/.dummy-config/test \
        ${builtins.toFile "test" "config"}
      assertFileContent \
        home-files/.dummy-data/test \
        ${builtins.toFile "test" "data"}
      assertFileContent \
        home-files/.dummy-cache/test \
        ${builtins.toFile "test" "cache"}
    '';
  };
}
