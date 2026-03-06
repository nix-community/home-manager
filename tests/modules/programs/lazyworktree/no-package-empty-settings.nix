{
  programs.lazyworktree = {
    enable = true;
    package = null;
    settings = { };
  };

  nmt.script = ''
    assertPathNotExists home-path/bin/lazyworktree
    assertPathNotExists home-files/.config/lazyworktree/config.yaml
  '';
}
