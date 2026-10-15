{
  programs.pi-coding-agent = {
    enable = true;
    configDir = "/home/testuser/.config/pi/agent";
  };

  test.stubs.pi-coding-agent = {
    name = "pi-coding-agent";
    outPath = null;
    buildScript = ''
      mkdir -p $out/bin
      echo '#!/bin/sh' > $out/bin/pi
      chmod +x $out/bin/pi
    '';
  };

  nmt.script = ''
    # Verify the wrapper sets the env var for non-default configDir
    assertFileRegex home-path/bin/pi \
      'PI_CODING_AGENT_DIR.*/home/testuser/.config/pi/agent'

    # The env var should no longer be exported via session variables
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh \
      'PI_CODING_AGENT_DIR'
  '';
}
