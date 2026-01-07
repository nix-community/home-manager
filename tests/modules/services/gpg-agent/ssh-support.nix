{
  programs.bash.enable = true;
  programs.fish.enable = true;
  programs.nushell.enable = true;
  programs.zsh.enable = true;

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
  };

  nmt.script = ''
    assertFileContains \
      home-files/.profile \
      'export SSH_AUTH_SOCK="$(@gnupg@/bin/gpgconf --list-dirs agent-ssh-socket)"'
    assertFileContains \
      home-files/.config/fish/config.fish \
      'set -x SSH_AUTH_SOCK (@gnupg@/bin/gpgconf --list-dirs agent-ssh-socket)'
    assertFileContains \
      home-files/.config/nushell/config.nu \
      '$env.SSH_AUTH_SOCK = $"(@gnupg@/bin/gpgconf --list-dirs agent-ssh-socket)"'
    assertFileContains \
      home-files/.zshenv \
      'export SSH_AUTH_SOCK="$(@gnupg@/bin/gpgconf --list-dirs agent-ssh-socket)"'

    assertFileContains \
      home-files/.bashrc \
      '@gnupg@/bin/gpg-connect-agent --quiet updatestartuptty /bye'
    assertFileContains \
      home-files/.config/fish/config.fish \
      '@gnupg@/bin/gpg-connect-agent --quiet updatestartuptty /bye'
    assertFileContains \
      home-files/.config/nushell/config.nu \
      '@gnupg@/bin/gpg-connect-agent --quiet updatestartuptty /bye'
    assertFileContains \
      home-files/.zshrc \
      '@gnupg@/bin/gpg-connect-agent --quiet updatestartuptty /bye'
  '';
}
