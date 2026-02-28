{
  programs.lazyworktree = {
    enable = true;
    settings = {
      worktree_dir = "~/.local/share/worktrees";
      sort_mode = "switched";
      layout = "default";
      auto_refresh = true;
      ci_auto_refresh = false;
      refresh_interval = 10;
      disable_pr = false;
      icon_set = "nerd-font-v3";
      search_auto_select = false;
      fuzzy_finder_input = false;
      palette_mru = true;
      palette_mru_limit = 5;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/lazyworktree/config.yaml
    assertFileContent home-files/.config/lazyworktree/config.yaml \
      ${./config.yaml}
  '';
}
