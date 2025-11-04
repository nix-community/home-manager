{
  programs.bash.enable = true;

  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
  };

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileContains home-files/.bashrc 'function yy() {'
    assertFileContains home-files/.bashrc 'local tmp="$(mktemp -t "yazi-cwd.XXXXX")"'
    assertFileContains home-files/.bashrc 'yazi "$@" --cwd-file="$tmp"'
    assertFileContains home-files/.bashrc 'if cwd="$(<"$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then'
    assertFileContains home-files/.bashrc 'builtin cd -- "$cwd"'
    assertFileContains home-files/.bashrc 'rm -f -- "$tmp"'
  '';
}
