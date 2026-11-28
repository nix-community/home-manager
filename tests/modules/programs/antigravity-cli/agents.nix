{ pkgs, realPkgs, ... }:

let
  src = realPkgs.runCommand "antigravity-cli-ifd-agent-source" { } ''
    mkdir -p "$out/agents/external-agent"
    echo '# External Agent' > "$out/agents/external-agent/agent.md"
  '';
in
{
  programs.antigravity-cli = {
    enable = true;
    package = pkgs.writeShellScriptBin "antigravity-cli" "";
    agents = {
      code-reviewer = ./agents/code-reviewer/agent.md;
      security-auditor = ./agents/security-auditor;
      refactorer = ''
        ---
        name: refactorer
        description: Focused refactoring agent for simplifying complex functions.
        ---

        You are a refactoring specialist. Keep changes minimal and preserve behavior.
      '';
      store-dir = "${src}/agents/external-agent";
      store-file = "${src}/agents/external-agent/agent.md";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.gemini/config/agents/code-reviewer/agent.md
    assertFileContent home-files/.gemini/config/agents/code-reviewer/agent.md \
      ${./agents/code-reviewer/agent.md}

    assertFileExists home-files/.gemini/config/agents/security-auditor/agent.md
    assertFileContent home-files/.gemini/config/agents/security-auditor/agent.md \
      ${./agents/security-auditor/agent.md}

    assertFileExists home-files/.gemini/config/agents/refactorer/agent.md
    assertFileContent home-files/.gemini/config/agents/refactorer/agent.md \
      ${./agents/refactorer.md}

    assertFileContent home-files/.gemini/config/agents/store-dir/agent.md \
      "${src}/agents/external-agent/agent.md"
    assertFileContent home-files/.gemini/config/agents/store-file/agent.md \
      "${src}/agents/external-agent/agent.md"
  '';
}
