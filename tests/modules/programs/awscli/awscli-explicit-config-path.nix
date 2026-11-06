{ config, ... }:

{
  programs.awscli = {
    enable = true;
    configFile = "${config.home.homeDirectory}/dotfiles/aws/config";
    settings = {
      default = {
        output = "json";
        region = "eu-west-3";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/dotfiles/aws/config
    assertFileContent home-files/dotfiles/aws/config \
      ${./aws-config.conf}

    assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
      'export AWS_CONFIG_FILE="${config.home.homeDirectory}/dotfiles/aws/config"'
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh 'AWS_SHARED_CREDENTIALS_FILE'
  '';
}
