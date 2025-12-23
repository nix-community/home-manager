{
  services.ssh-agent = {
    enable = true;
    enableNushellIntegration = true;
    forceOverride = true;
  };

  programs.nushell.enable = true;

  nmt.script = ''
    assertFileContains \
      home-files/.config/nushell/config.nu \
      '$env.SSH_AUTH_SOCK = $"($env.XDG_RUNTIME_DIR)/ssh-agent"'
    assertFileNotRegex \
      home-files/.config/nushell/config.nu \
      'if "SSH_AUTH_SOCK" not-in \$env \{'
  '';
}
