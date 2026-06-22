{
  programs.bash.enable = true;
  programs.fish.enable = true;
  programs.zsh.enable = true;

  programs.lazyworktree = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    enableZshIntegration = true;
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

    assertFileExists home-files/.bashrc
    assertFileContains home-files/.bashrc 'function lwt() {'
    assertFileContains home-files/.bashrc 'lazyworktree_dir="$(command lazyworktree "$@")" || return'

    assertFileExists home-files/.zshrc
    assertFileContains home-files/.zshrc 'function lwt() {'
    assertFileContains home-files/.zshrc 'lazyworktree_dir="$(command lazyworktree "$@")" || return'

    assertFileExists home-files/.config/fish/functions/lwt.fish
    assertFileContains home-files/.config/fish/functions/lwt.fish 'set -l lazyworktree_dir (command lazyworktree $argv)'
  '';
}
