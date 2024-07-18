{ config, lib, ... }:

{
  config = {
    programs.alacritty = {
      enable = true;
      package = config.lib.test.mkStubPackage { };

      settings = {
        window.dimensions = {
          lines = 3;
          columns = 200;
        };

        keyboard.bindings = [{
          key = "K";
          mods = "Control";
          chars = "\\u000c";
        }];

        font = let
          defaultFont =
            lib.mkMerge [ (lib.mkIf true "SFMono") (lib.mkIf false "Iosevka") ];
        in {
          normal.family = defaultFont;
          bold.family = defaultFont;
        };
      };
    };

    nmt.script = ''
      assertFileContent \
        home-files/.config/alacritty/alacritty.toml \
        ${./settings-toml-expected.toml}
    '';
  };
}
