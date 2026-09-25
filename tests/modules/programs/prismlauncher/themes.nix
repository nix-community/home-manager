{ pkgs, ... }:

let
  inherit (pkgs)
    formats
    runCommand
    stdenv
    writeText
    ;

  jsonFormat = formats.json { };

  themeAttrs = {
    theme = {
      name = "Custom";
      colors = {
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

  expectedTheme = jsonFormat.generate "theme.json" themeAttrs.theme;
  expectedStyle = writeText "themeStyle.css" themeAttrs.style;

  themeDir = runCommand "foobar-theme" { } ''
    mkdir $out
    ln -s ${expectedTheme} $out/theme.json
    ln -s ${expectedStyle} $out/themeStyle.css
  '';

  dataDir =
    (if stdenv.hostPlatform.isDarwin then "Library/Application Support" else ".local/share")
    + "/PrismLauncher";
in

{
  programs.prismlauncher = {
    enable = true;

    themes = {
      theme-attrs = themeAttrs;
      theme-dir = themeDir;
    };
  };

  nmt.script = ''
    basePath='home-files/${dataDir}/themes'

    assertFileExists "$basePath/theme-attrs/theme.json"
    assertFileContent "$basePath/theme-attrs/theme.json" ${expectedTheme}
    assertFileExists "$basePath/theme-attrs/themeStyle.css"
    assertFileContent "$basePath/theme-attrs/themeStyle.css" ${expectedStyle}

    assertFileExists "$basePath/theme-dir/theme.json"
    assertFileContent "$basePath/theme-dir/theme.json" ${expectedTheme}
    assertFileExists "$basePath/theme-dir/themeStyle.css"
    assertFileContent "$basePath/theme-dir/themeStyle.css" ${expectedStyle}
  '';
}
