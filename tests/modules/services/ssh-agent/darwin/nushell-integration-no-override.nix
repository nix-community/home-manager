{
  services.ssh-agent = {
    enable = true;
    enableNushellIntegration = true;
    forceOverride = false;
  };

  programs.nushell.enable = true;

  nmt.script = ''
    assertFileContains \
      home-files/.config/nushell/config.nu \
      'if "SSH_AUTH_SOCK" not-in $env {'
  '';
}
