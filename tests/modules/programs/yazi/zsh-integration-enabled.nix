{
  programs.zsh.enable = true;

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
  };

  nmt.script = ''
    assertFileExists home-files/.zshrc
    assertFileContains home-files/.zshrc 'function yy() {'
    assertFileContains home-files/.zshrc 'local tmp="$(mktemp -t "yazi-cwd.XXXXX")"'
    assertFileContains home-files/.zshrc 'command yazi "$@" --cwd-file="$tmp"'
    assertFileContains home-files/.zshrc 'if cwd="$(<"$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then'
    assertFileContains home-files/.zshrc 'builtin cd -- "$cwd"'
    assertFileContains home-files/.zshrc 'rm -f -- "$tmp"'
  '';
}
