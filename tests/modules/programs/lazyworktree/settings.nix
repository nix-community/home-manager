{
  programs.lazyworktree = {
    enable = true;
    settings = {
      worktree_dir = "~/.local/share/worktrees";
      sort_mode = "switched";
      auto_fetch_prs = false;
      auto_refresh = true;
      refresh_interval = 10;
      icon_set = "nerd-font-v3";
      search_auto_select = false;
      fuzzy_finder_input = false;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/lazyworktree/config.yaml
    assertFileContent home-files/.config/lazyworktree/config.yaml \
      ${./config.yaml}
  '';
}
