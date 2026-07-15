{ config, ... }:
{
  # agentReview writes both agent keys, with the instructions directory
  # shell-quoted inside the shlex-split command.
  programs.git.enable = true;

  programs.b4 = {
    enable = true;
    agentReview = {
      enable = true;
      instructions = "/some dir/agent-reviewer.md";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/git/config
    assertFileContains home-files/.config/git/config '[b4]'
    assertFileContains home-files/.config/git/config \
      "review-agent-command = \"${config.programs.b4.agentReview.command}\""
    assertFileContains home-files/.config/git/config \
      "review-agent-prompt-path = \"/some dir/agent-reviewer.md\""
    assertFileContains home-files/.config/git/config "add-dir '/some dir'"
  '';
}
