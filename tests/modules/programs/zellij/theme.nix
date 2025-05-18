{ pkgs, ... }:
{
  programs.zellij = {
    enable = true;
    themes = {
      example.themes.example = {
        ribbon_unselected = {
          base = [
            0
            0
            0
          ];
          background = [
            255
            153
            0
          ];
          emphasis_0 = [
            255
            53
            94
          ];
          emphasis_1 = [
            255
            255
            255
          ];
          emphasis_2 = [
            0
            217
            227
          ];
          emphasis_3 = [
            255
            0
            255
          ];
        };
      };
      text = ''
        themes {
          example {
            ribbon_unselected {
              background 255 153 0
              base 0 0 0
              emphasis_0 255 53 94
              emphasis_1 255 255 255
              emphasis_2 0 217 227
              emphasis_3 255 0 255
            }
          }
        }
      '';
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/zellij/themes/example.kdl
    assertFileContent home-files/.config/zellij/themes/text.kdl \
      ${pkgs.writeText "theme-text-expected" ''
        themes {
          example {
            ribbon_unselected {
              background 255 153 0
              base 0 0 0
              emphasis_0 255 53 94
              emphasis_1 255 255 255
              emphasis_2 0 217 227
              emphasis_3 255 0 255
            }
          }
        }
      ''}
  '';
}
