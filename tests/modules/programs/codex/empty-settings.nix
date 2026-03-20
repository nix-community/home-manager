{
  programs.codex = {
    enable = true;
    settings = { };
  };
  nmt.script = ''
    assertPathNotExists home-files/.codex/config.toml
    assertPathNotExists home-files/.codex/config.yaml
    assertPathNotExists home-files/.codex/AGENTS.md
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh 'CODEX_HOME'
  '';
}
