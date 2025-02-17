{ ... }:

{
  programs = {
    bash.enable = true;
    git-worktree-switcher.enable = true;
  };

  test.stubs.git-worktree-switcher = { name = "git-worktree-switcher"; };

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileContains \
      home-files/.bashrc \
      'eval "$(@git-worktree-switcher@/bin/git-worktree-switcher init bash)"'
  '';
}
