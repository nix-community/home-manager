_: {
  home.preferXdgDirectories = false;
  programs.lakectl = {
    enable = true;
    settings = {
      credentials = {
        access_key_id = "AKIAIOSFODNN7EXAMPLE";
        secret_access_key = "secret";
      };
      server.endpoint_url = "http://127.0.0.1:8000";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.lakectl.yaml
    assertFileContent home-files/.lakectl.yaml \
      ${./config.yaml}

    assertFileExists home-path/etc/profile.d/hm-session-vars.sh
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh \
      'LAKECTL_CONFIG_FILE'
  '';
}
