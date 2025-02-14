# Test custom theme functionality
{ config, ... }: {
  programs.zed-editor = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
    userThemes = [{
      name = "Test";
      author = "user";
      themes = [{
        name = "Test Catppuccin";
        appearance = "light";
        style = {
          editor = {
            foreground = "#4c4f69";
            background = "#eff1f5";
            gutter.background = "#eff1f5";
            subheader.background = "#e6e9ef";
            active_line.background = "#4c4f690d";
            highlighted_line.background = null;
            line_number = "#8c8fa1";
            active_line_number = "#8839ef";
            invisible = "#7c7f9366";
            wrap_guide = "#acb0be";
          };
        };
      }];
    }];
  };

  nmt.script = let
    expectedContent = builtins.toFile "expected.json" ''
      {
        "author": "user",
        "name": "test",
        "themes": [
          {
            "appearance": "light",
            "name": "Test Catppuccin",
            "style": {
              "editor": {
                "active_line": {
                  "background": "#4c4f690d"
                },
                "active_line_number": "#8839ef",
                "background": "#eff1f5",
                "foreground": "#4c4f69",
                "gutter": {
                  "background": "#eff1f5"
                },
                "highlighted_line": {
                  "background": null
                },
                "invisible": "#7c7f9366",
                "line_number": "#8c8fa1",
                "subheader": {
                  "background": "#e6e9ef"
                },
                "wrap_guide": "#acb0be"
              }
            }
          }
        ]
      }
    '';

    testPath = ".config/zed/themes/test.json";
  in ''
    assertFileExists "home-files/${testPath}"
    assertFileContent "home-files/${testPath}" "${expectedContent}"
  '';
}
