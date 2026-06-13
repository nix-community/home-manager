{ config, ... }:

{
  programs.prismlauncher = {
    enable = true;
    package = config.lib.test.mkStubPackage { };

    themes = {
      theme-dir = ./theme-dir;

      inline-theme = {
        theme = {
          name = "Inline Theme";
          colors = {
            accent = "#7aa2f7";
            background = "#1a1b26";
            foreground = "#c0caf5";
          };
        };
        style = ''
          QWidget {
            font-family: "Inter";
          }
        '';
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.local/share/PrismLauncher/themes/theme-dir/theme.json
    assertFileContent \
      home-files/.local/share/PrismLauncher/themes/theme-dir/theme.json \
      ${./theme-dir/theme.json}
    assertFileExists home-files/.local/share/PrismLauncher/themes/theme-dir/themeStyle.css
    assertFileContent \
      home-files/.local/share/PrismLauncher/themes/theme-dir/themeStyle.css \
      ${./theme-dir/themeStyle.css}

    assertFileExists home-files/.local/share/PrismLauncher/themes/inline-theme/theme.json
    assertFileContent \
      home-files/.local/share/PrismLauncher/themes/inline-theme/theme.json \
      ${./inline-theme.json}
    assertFileExists home-files/.local/share/PrismLauncher/themes/inline-theme/themeStyle.css
    assertFileContent \
      home-files/.local/share/PrismLauncher/themes/inline-theme/themeStyle.css \
      ${./inline-themeStyle.css}
  '';
}
