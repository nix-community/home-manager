{
  programs.codex = {
    enable = true;
    settings = { };
  };
  nmt.script = ''
    assertPathNotExists home-files/.codex/config.toml
    assertPathNotExists home-files/.codex/config.yaml
  '';
}
