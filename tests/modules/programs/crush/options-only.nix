{
  programs.crush = {
    enable = true;

    settings.options = {
      disabled_tools = [ "bash" ];
      skills_paths = [ "~/.config/crush/skills" ];
      initialize_as = "AGENTS.md";
      disable_metrics = true;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/crush/crush.json
    assertFileContent home-files/.config/crush/crush.json ${./expected-options-only.json}
  '';
}
