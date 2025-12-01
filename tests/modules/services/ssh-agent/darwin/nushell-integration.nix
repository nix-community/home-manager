{
  services.ssh-agent = {
    enable = true;
    enableNushellIntegration = true;
  };

  programs.nushell.enable = true;

  nmt.script = ''
    assertFileContains \
      home-files/.config/nushell/config.nu \
      '$env.SSH_AUTH_SOCK = $"(@getconf-system_cmds@/bin/getconf DARWIN_USER_TEMP_DIR)/ssh-agent"'
  '';
}
