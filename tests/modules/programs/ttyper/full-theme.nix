{ pkgs, ... }:
{
  programs.ttyper = {
    enable = true;
    package = pkgs.writeScriptBin "dummy-ttyper" "";

    settings.theme = {
      border_type = "rounded";
      default = "none";
      title = "white;bold";
      input_border = "cyan";
      prompt_border = "green";
      prompt_correct = "green";
      prompt_incorrect = "red";
      prompt_untyped = "gray";
      prompt_current_correct = "green;bold";
      prompt_current_incorrect = "red;bold";
      prompt_current_untyped = "blue;bold";
      prompt_cursor = "none;underlined";
      results_overview = "cyan;bold";
      results_overview_border = "cyan";
      results_worst_keys = "cyan;bold";
      results_worst_keys_border = "cyan";
      results_chart = "cyan";
      results_chart_x = "cyan";
      results_chart_y = "gray;italic";
      results_restart_prompt = "gray;italic";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/ttyper/config.toml
    assertFileContent \
      home-files/.config/ttyper/config.toml \
      ${./full-theme-expected.toml}
  '';
}
