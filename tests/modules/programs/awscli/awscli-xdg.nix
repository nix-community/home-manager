{ config, ... }:

{
  home.preferXdgDirectories = true;

  programs.awscli = {
    enable = true;
    settings = {
      default = {
        output = "json";
        region = "eu-west-3";
      };
    };
    credentials = {
      iam = {
        credential_process = "pass show aws";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/aws/config
    assertFileContent home-files/.config/aws/config \
      ${./aws-config.conf}

    assertFileExists home-files/.config/aws/credentials
    assertFileContent home-files/.config/aws/credentials \
      ${./aws-credentials.conf}

    assertFileExists home-path/etc/profile.d/hm-session-vars.sh
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
      'export AWS_CONFIG_FILE="${config.xdg.configHome}/aws/config"'
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
      'export AWS_SHARED_CREDENTIALS_FILE="${config.xdg.configHome}/aws/credentials"'
  '';
}
