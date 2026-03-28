{
  programs.amp-cli = {
    enable = true;

    settings = {
      "amp.terminal.theme" = "catppuccin-mocha";
      "amp.notifications.enabled" = true;
      "amp.showCosts" = false;
      "amp.anthropic.thinking.enabled" = true;
      "amp.git.commit.coauthor.enabled" = true;
      "amp.git.commit.ampThread.enabled" = false;
      "amp.tools.disable" = [
        "browser_navigate"
        "builtin:edit_file"
      ];
      "amp.permissions" = [
        {
          tool = "Bash";
          command = "git *";
          allow = true;
        }
        {
          tool = "Bash";
          command = "curl *";
          allow = false;
        }
      ];
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/amp/settings.json
    assertFileContent home-files/.config/amp/settings.json ${./expected-settings.json}
  '';
}
