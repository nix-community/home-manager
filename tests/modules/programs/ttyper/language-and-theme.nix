{ pkgs, ... }:
{
  programs.ttyper = {
    enable = true;
    package = pkgs.writeScriptBin "dummy-ttyper" "";

    settings = {
      default_language = "rust";
      theme = {
        border_type = "double";
        input_border = {
          fg = "magenta";
        };
        prompt_correct = {
          fg = "green";
          modifiers = [ "bold" ];
        };
        prompt_incorrect = {
          fg = "red";
          modifiers = [ "bold" ];
        };
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/ttyper/config.toml
    assertFileContent \
      home-files/.config/ttyper/config.toml \
      ${./language-and-theme-expected.toml}
  '';
}
