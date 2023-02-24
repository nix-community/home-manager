{ ... }:

{
  programs.vivid = {
    enable = true;

    theme = "one-dark";
    filetypes = {
      core = {
        regular_file = [ "$fi" ];
        directory = [ "$di" ];
      };
      text = {
        licenses = [ "COPYING" "LICENSE" ];
        programming = {
          source = {
            latex = [ ".tex" ".ltx" ];
            lisp = [ ".lisp" ".el" ];
          };
        };
      };
    };
    themes = {
      mytheme = {
        colors = { blue = "0031a9"; };
        core = {
          directory = {
            foreground = "blue";
            font-style = "bold";
          };
        };
      };
    };
  };

  test.stubs.vivid = { };

  nmt.script = ''
    assertFileContent home-files/.config/vivid/filetypes.yml \
    ${builtins.toFile "vivid-expected-filetypes.yml" ''
      {
        "core": {
          "directory": [
            "$di"
          ],
          "regular_file": [
            "$fi"
          ]
        },
        "text": {
          "licenses": [
            "COPYING",
            "LICENSE"
          ],
          "programming": {
            "source": {
              "latex": [
                ".tex",
                ".ltx"
              ],
              "lisp": [
                ".lisp",
                ".el"
              ]
            }
          }
        }
      }
    ''}
    assertFileContent home-files/.config/vivid/themes/mytheme.yml \
    ${builtins.toFile "mytheme-expected-theme.yml" ''
      {
        "colors": {
          "blue": "0031a9"
        },
        "core": {
          "directory": {
            "font-style": "bold",
            "foreground": "blue"
          }
        }
      }
    ''}
  '';
}
