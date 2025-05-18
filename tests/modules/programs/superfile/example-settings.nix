{
  config,
  pkgs,
  lib,
  ...
}:

{
  xdg.enable = lib.mkIf pkgs.stdenv.isDarwin false;

  programs.superfile = {
    enable = true;
    package = config.lib.test.mkStubPackage { };

    settings = {
      theme = "catppuccin-frappe";
      default_sort_type = 0;
      transparent_background = false;
    };
    hotkeys = {
      confirm = [
        "enter"
        "right"
        "l"
      ];
    };
    themes = {
      test0 = {
        code_syntax_highlight = "catppuccin-latte";

        file_panel_border = "#101010";
        sidebar_border = "#101011";
        footer_border = "#101012";

        gradient_color = [
          "#101013"
          "#101014"
        ];
      };

      test1 = ./example-theme-expected.toml;

      test2 = {
        code_syntax_highlight = "catppuccin-frappe";

        file_panel_border = "#202020";
        sidebar_border = "#202021";
        footer_border = "#202022";

        gradient_color = [
          "#202023"
          "#202024"
        ];
      };
    };
  };

  nmt.script =
    let
      configSubPath =
        if !pkgs.stdenv.isDarwin then ".config/superfile" else "Library/Application Support/superfile";
      configBasePath = "home-files/" + configSubPath;
    in
    ''
      assertFileExists "${configBasePath}/config.toml"
      assertFileContent \
        "${configBasePath}/config.toml" \
        ${./example-config-expected.toml}
      assertFileExists "${configBasePath}/hotkeys.toml"
      assertFileContent \
        "${configBasePath}/hotkeys.toml" \
        ${./example-hotkeys-expected.toml}
      assertFileExists "${configBasePath}/theme/test0.toml"
      assertFileContent \
        "${configBasePath}/theme/test0.toml" \
        ${./example-theme-expected.toml}
      assertFileExists "${configBasePath}/theme/test1.toml"
      assertFileContent \
        "${configBasePath}/theme/test1.toml" \
        ${./example-theme-expected.toml}
      assertFileExists "${configBasePath}/theme/test2.toml"
      assertFileContent \
        "${configBasePath}/theme/test2.toml" \
        ${./example-theme2-expected.toml}
    '';
}
