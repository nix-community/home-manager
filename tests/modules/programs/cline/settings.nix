{
  programs.cline = {
    enable = true;
    package = null;
    settings = {
      autoUpdateEnabled = false;
      tools.web_search.enabled = true;
    };
    providers = {
      version = 1;
      providers.claude-code = {
        settings.provider = "claude-code";
        tokenSource = "manual";
      };
    };
    models = {
      version = 1;
      providers.anthropic.models.claude-haiku-4-5 = {
        id = "claude-haiku-4-5";
        name = "Claude Haiku 4.5";
      };
    };
  };

  nmt.script = ''
    assertFileContent home-files/.cline/data/settings/global-settings.json \
      ${./settings-expected.json}
    assertFileContent home-files/.cline/data/settings/providers.json \
      ${./providers-expected.json}
    assertFileContent home-files/.cline/data/settings/models.json \
      ${./models-expected.json}
    assertPathNotExists home-files/.cline/data/settings/cline_mcp_settings.json
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh 'CLINE_DIR'
  '';
}
