{ pkgs, ... }:
{
  programs.foliate = {
    enable = true;
    settings = {
      color-scheme = 0;
      library = {
        view-mode = "grid";
        show-covers = true;
      };
      "viewer/view" = {
        theme = "My Theme";
      };
      "viewer/font" = {
        monospace = "Maple Mono";
        default-size = 12;
      };
    };
    themes.myTheme = {
      label = "My Theme";
      light = {
        fg = "#89b4fa";
        bg = "#1e1e2e";
        link = "#89b4fa";
      };
      dark = { };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/com.github.johnfactotum.Foliate/themes/myTheme.json
    assertFileContent home-files/.config/com.github.johnfactotum.Foliate/themes/myTheme.json \
      ${pkgs.writeText "expected-foliate-theme" ''
        {
          "dark": {},
          "label": "My Theme",
          "light": {
            "bg": "#1e1e2e",
            "fg": "#89b4fa",
            "link": "#89b4fa"
          }
        }
      ''}
  '';
}
