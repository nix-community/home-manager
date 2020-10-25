{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    xdg.configFile.test.text = "config";
    xdg.dataFile.test.text = "data";
    home.file.test.text = "home";

    nmt.script = ''
      assertFileExists home-files/.config/test
      assertFileExists home-files/.local/share/test
      assertFileExists home-files/test
      assertFileContent \
        home-files/.config/test \
        ${builtins.toFile "test" "config"}
      assertFileContent \
        home-files/.local/share/test \
        ${builtins.toFile "test" "data"}
      assertFileContent \
        home-files/test \
        ${builtins.toFile "test" "home"}
    '';
  };
}
