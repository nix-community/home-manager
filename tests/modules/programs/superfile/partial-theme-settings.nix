# When not specified in `programs.superfile.settings.theme`,
# test that the first skin name (alphabetically) is used in the config file
{ pkgs, lib, ... }:
{
  xdg.enable = lib.mkIf pkgs.stdenv.isDarwin false;

  programs.superfile = {
    enable = true;
    settings = {
      transparent_background = false;
    };
    themes = {
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
        ${./partial-theme-settings-expected.toml}
    '';
}
