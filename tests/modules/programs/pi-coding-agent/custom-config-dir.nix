{
  programs.pi-coding-agent = {
    enable = true;
    configDir = "/home/testuser/.config/pi/agent";
  };
  nmt.script = ''
    # Verify env var is set for non-default configDir
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
      'PI_CODING_AGENT_DIR'
  '';
}
