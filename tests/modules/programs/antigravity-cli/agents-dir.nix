{ pkgs, ... }:

{
  programs.antigravity-cli = {
    enable = true;
    package = pkgs.writeShellScriptBin "antigravity-cli" "";
    agents = ./agents;
  };

  nmt.script = ''
    assertFileExists home-files/.gemini/config/agents/code-reviewer/agent.md
    assertLinkExists home-files/.gemini/config/agents/code-reviewer/agent.md
    assertFileContent home-files/.gemini/config/agents/code-reviewer/agent.md \
      ${./agents/code-reviewer/agent.md}

    assertFileExists home-files/.gemini/config/agents/security-auditor/agent.md
    assertLinkExists home-files/.gemini/config/agents/security-auditor/agent.md
    assertFileContent home-files/.gemini/config/agents/security-auditor/agent.md \
      ${./agents/security-auditor/agent.md}

    assertFileExists home-files/.gemini/config/agents/refactorer.md
    assertLinkExists home-files/.gemini/config/agents/refactorer.md
    assertFileContent home-files/.gemini/config/agents/refactorer.md \
      ${./agents/refactorer.md}
  '';
}
