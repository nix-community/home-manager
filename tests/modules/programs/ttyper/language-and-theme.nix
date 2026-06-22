{ pkgs, ... }:
{
  programs.ttyper = {
    enable = true;
    package = pkgs.writeScriptBin "dummy-ttyper" "";

    settings = {
      default_language = "rust";
      theme = {
        border_type = "double";
        input_border = "magenta";
        prompt_correct = "green;bold";
        prompt_incorrect = "red;bold";
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
