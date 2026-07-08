{
  programs.posting = {
    enable = true;
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/posting/config.yaml
    assertPathNotExists home-files/.local/share/posting
  '';
}
