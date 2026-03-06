{ pkgs, ... }:
{
  programs.ttyper = {
    enable = true;
    package = pkgs.writeScriptBin "dummy-ttyper" "";

    settings.theme = {
      border_type = "rounded";
      default = {
        fg = "none";
      };
      title = {
        fg = "white";
        modifiers = [ "bold" ];
      };
      input_border = {
        fg = "cyan";
      };
      prompt_border = {
        fg = "green";
      };
      prompt_correct = {
        fg = "green";
      };
      prompt_incorrect = {
        fg = "red";
      };
      prompt_untyped = {
        fg = "gray";
      };
      prompt_current_correct = {
        fg = "green";
        modifiers = [ "bold" ];
      };
      prompt_current_incorrect = {
        fg = "red";
        modifiers = [ "bold" ];
      };
      prompt_current_untyped = {
        fg = "blue";
        modifiers = [ "bold" ];
      };
      prompt_cursor = {
        modifiers = [ "underlined" ];
      };
      results_overview = {
        fg = "cyan";
        modifiers = [ "bold" ];
      };
      results_overview_border = {
        fg = "cyan";
      };
      results_worst_keys = {
        fg = "cyan";
        modifiers = [ "bold" ];
      };
      results_worst_keys_border = {
        fg = "cyan";
      };
      results_chart = {
        fg = "cyan";
      };
      results_chart_x = {
        fg = "cyan";
      };
      results_chart_y = {
        fg = "gray";
        modifiers = [ "italic" ];
      };
      results_restart_prompt = {
        fg = "gray";
        modifiers = [ "italic" ];
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/ttyper/config.toml
    assertFileContent \
      home-files/.config/ttyper/config.toml \
      ${./full-theme-expected.toml}
  '';
}
