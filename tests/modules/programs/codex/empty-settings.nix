{
  programs.codex = {
    enable = true;
    settings = { };
  };
  nmt.script = ''
    assertPathNotExists home-files/.codex/config.toml
    assertPathNotExists home-files/.codex/config.yaml
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh 'CODEX_HOME'
  '';
}
