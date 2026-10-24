{ config, ... }:
{
  home.preferXdgDirectories = true;
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
    assertFileExists home-files/.config/lakectl/config.yaml
    assertFileContent home-files/.config/lakectl/config.yaml \
      ${./config.yaml}

    assertFileExists home-path/etc/profile.d/hm-session-vars.sh
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
      'export LAKECTL_CONFIG_FILE="${config.xdg.configHome}/lakectl/config.yaml"'
  '';
}
