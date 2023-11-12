{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.lsd = {
      enable = true;
      enableAliases = false;
      settings = {
        date = "relative";
        blocks = [ "date" "size" "name" ];
        layout = "oneline";
        sorting.dir-grouping = "first";
        ignore-globs = [ ".git" ".hg" ".bsp" ];
      };
      colors = {
        date = {
          day-old = "green";
          older = "dark_green";
        };
        size = {
          none = "grey";
          small = "grey";
          medium = "yellow";
          large = "dark_yellow";
        };
      };
    };

    test.stubs.lsd = { };

    nmt.script = ''
      assertFileExists home-files/.config/lsd/config.yaml
      assertFileExists home-files/.config/lsd/colors.yaml
      assertFileContent \
        home-files/.config/lsd/config.yaml \
        ${./example-settings-expected.yaml}
      assertFileContent \
        home-files/.config/lsd/colors.yaml \
        ${./example-colors-expected.yaml}
    '';
  };
}
