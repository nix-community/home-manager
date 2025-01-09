{ config, ... }:

{
  config = {
    home.stateVersion = "22.05";

    programs.waybar = {
      package = config.lib.test.mkStubPackage { outPath = "@waybar@"; };
      enable = true;
      settings = [{
        modules-center = [ "test" ];
        modules = { "test" = { }; };
      }];
    };

    test.asserts.assertions.expected = [''
      The `programs.waybar.settings.[].modules` option has been removed.
      It is now possible to declare modules in the configuration without nesting them under the `modules` option.
    ''];

    nmt.script = ''
      assertPathNotExists home-files/.config/waybar/style.css
      assertFileContent \
        home-files/.config/waybar/config \
          ${
            builtins.toFile "waybar-deprecated-modules-option.json" ''
              [
                {
                  "modules-center": [
                    "test"
                  ],
                  "test": {}
                }
              ]
            ''
          }
    '';
  };
}
