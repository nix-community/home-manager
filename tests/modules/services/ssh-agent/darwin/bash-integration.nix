{
  services.ssh-agent = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.bash.enable = true;

  nmt.script = ''
    assertFileContains \
      home-files/.bashrc \
      'export SSH_AUTH_SOCK=$(@getconf-system_cmds@/bin/getconf DARWIN_USER_TEMP_DIR)/ssh-agent'
  '';
}
