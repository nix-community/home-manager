{
  time = "2026-07-14T00:00:00+00:00";
  condition = true;
  message = ''
    A new module is available: 'programs.b4'.

    b4 is a tool for working with kernel-style patch and email review
    workflows on lore.kernel.org. The module installs b4 and writes its
    configuration to git-config's [b4] section via `programs.b4.settings`. It
    can also wire b4's review-editor syntax highlighting into Vim/Neovim/Emacs
    and exposes b4's shipped agent-reviewer instructions for driving an AI
    reviewer.
  '';
}
