{
  programs.bash.enable = true;
  programs.fish.enable = true;
  programs.nushell.enable = true;
  programs.zsh.enable = true;

  sshAuthSock.enable = false;

  nmt.script = ''
    assertFileNotRegex \
      home-files/.profile \
      'SSH_AUTH_SOCK'
    assertFileNotRegex \
      home-files/.config/fish/config.fish \
      'SSH_AUTH_SOCK'
    assertFileNotRegex \
      home-files/.config/nushell/config.nu \
      'SSH_AUTH_SOCK'
    assertFileNotRegex \
      home-files/.zshenv \
      'SSH_AUTH_SOCK'
    assertFileNotRegex \
      home-files/.zprofile \
      'SSH_AUTH_SOCK'

    assertPathNotExists home-files/.config/systemd/user/set-SSH_AUTH_SOCK.service
  '';
}
