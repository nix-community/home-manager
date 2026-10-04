{
  home.preferXdgDirectories = true;
  programs.github-copilot-cli = {
    enable = true;
    package = null;
    context = ./context.md;
    settings = {
      model = "claude-sonnet-4-5";
      theme = "dark";
    };
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/copilot/config.json
    assertFileContent home-files/.config/copilot/settings.json ${./expected-config.json}
    assertPathNotExists home-files/.copilot/settings.json
    assertFileExists home-files/.config/copilot/copilot-instructions.md
    assertLinkExists home-files/.config/copilot/copilot-instructions.md
    assertFileContent home-files/.config/copilot/copilot-instructions.md \
      ${./context.md}
    assertPathNotExists home-files/.copilot/config.json
    assertPathNotExists home-files/.copilot/copilot-instructions.md
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
      'export COPILOT_HOME="/home/hm-user/.config/copilot"'
  '';
}
