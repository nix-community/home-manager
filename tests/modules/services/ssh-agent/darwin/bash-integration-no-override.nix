{
  services.ssh-agent = {
    enable = true;
    enableBashIntegration = true;
    forceOverride = false;
  };

  programs.bash.enable = true;

  nmt.script = ''
    assertFileContains \
      home-files/.profile \
      'if [ -z "$SSH_AUTH_SOCK" ]; then'
  '';
}
