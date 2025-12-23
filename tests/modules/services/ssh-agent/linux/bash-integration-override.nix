{
  services.ssh-agent = {
    enable = true;
    enableBashIntegration = true;
    forceOverride = true;
  };

  programs.bash.enable = true;

  nmt.script = ''
    assertFileContains \
      home-files/.profile \
      'export SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/ssh-agent'
    assertFileNotRegex \
      home-files/.profile \
      'if \[ -z "\$SSH_AUTH_SOCK" \]'
  '';
}
