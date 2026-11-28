{ pkgs, realPkgs, ... }:

let
  src = realPkgs.runCommand "antigravity-cli-ifd-agents-directory" { } ''
    mkdir -p "$out/agents/external-agent"
    echo '# External Agent' > "$out/agents/external-agent/agent.md"
  '';
in
{
  programs.antigravity-cli = {
    enable = true;
    package = pkgs.writeShellScriptBin "antigravity-cli" "";
    agents = "${src}/agents";
  };

  nmt.script = ''
    assertFileExists home-files/.gemini/config/agents/external-agent/agent.md
    assertLinkExists home-files/.gemini/config/agents/external-agent/agent.md
    assertFileContent home-files/.gemini/config/agents/external-agent/agent.md \
      "${src}/agents/external-agent/agent.md"
  '';
}
