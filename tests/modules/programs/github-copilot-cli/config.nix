{
  programs.github-copilot-cli = {
    enable = true;
    settings = {
      model = "claude-sonnet-4-5";
      theme = "dark";
      trusted_folders = [ "/home/user/projects" ];
    };
  };

  nmt.script = ''
    assertFileExists home-files/.copilot/config.json
    assertFileContent home-files/.copilot/config.json ${./expected-config.json}
    assertPathNotExists home-files/.copilot/mcp-config.json
  '';
}
