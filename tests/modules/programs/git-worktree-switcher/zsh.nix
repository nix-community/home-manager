{ ... }:

{
  programs = {
    zsh.enable = true;
    git-worktree-switcher.enable = true;
  };

  test.stubs.git-worktree-switcher = { name = "git-worktree-switcher"; };

  nmt.script = ''
    assertFileExists home-files/.zshrc
    assertFileContains \
      home-files/.zshrc \
      'eval "$(@git-worktree-switcher@/bin/git-worktree-switcher init zsh)"'
  '';
}
