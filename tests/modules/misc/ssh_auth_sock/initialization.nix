{
  programs.bash.enable = true;
  programs.fish.enable = true;
  programs.nushell.enable = true;
  programs.zsh.enable = true;

  ssh_auth_sock.initialization = {
    bash = "echo bash/zsh";
    fish = "echo fish";
    nushell = "echo nushell";
  };

  nmt.script = ''
    assertFileContains \
      home-files/.profile \
      'if [ -z "$SSH_AUTH_SOCK" -o -z "$SSH_CONNECTION" ]; then'
    assertFileContains \
      home-files/.config/fish/config.fish \
      'if test -z "$SSH_AUTH_SOCK"; or test -z "$SSH_CONNECTION"'
    assertFileContains \
      home-files/.config/nushell/config.nu \
      'if ("SSH_AUTH_SOCK" not-in $env) or ($env.SSH_AUTH_SOCK | is-empty) or ("SSH_CONNECTION" not-in $env) or ($env.SSH_CONNECTION | is-empty) {'
    assertFileContains \
      home-files/.zshenv \
      'if [ -z "$SSH_AUTH_SOCK" -o -z "$SSH_CONNECTION" ]; then'
  '';
}
