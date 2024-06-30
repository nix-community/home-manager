{ ... }:

let
  shellIntegration = ''
    function yy() {
      local tmp="$(mktemp -t "yazi-cwd.XXXXX")"
      yazi "$@" --cwd-file="$tmp"
      if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
      fi
      rm -f -- "$tmp"
    }
  '';
in {
  programs.zsh.enable = true;

  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
  };

  test.stubs.yazi = { };

  nmt.script = ''
    assertFileContains home-files/.zshrc '${shellIntegration}'
  '';
}
