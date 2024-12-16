{ ... }:

{
  programs = {
    fish.enable = true;
    git-worktree-switcher.enable = true;
  };

  test.stubs.git-worktree-switcher = { name = "git-worktree-switcher"; };

  nmt.script = ''
    assertFileExists home-files/.config/fish/config.fish
    assertFileContains \
      home-files/.config/fish/config.fish \
      '@git-worktree-switcher@/bin/git-worktree-switcher init fish | source'
  '';
}
