{
  programs.bash.enable = true;
  programs.fish.enable = true;
  programs.nushell.enable = true;
  programs.zsh.enable = true;
  services.ssh-agent.enable = true;

  nmt.script = ''
    assertFileContains \
      home-files/.profile \
      'export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent"'
    assertFileContains \
      home-files/.config/fish/config.fish \
      'set -x SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/ssh-agent"'
    assertFileContains \
      home-files/.config/nushell/config.nu \
      '$env.SSH_AUTH_SOCK = $"($env.XDG_RUNTIME_DIR)/ssh-agent"'
    assertFileContains \
      home-files/.zshenv \
      'export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent"'
  '';
}
