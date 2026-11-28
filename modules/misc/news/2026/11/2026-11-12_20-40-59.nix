{ config, ... }:
{
  time = "2026-11-13T01:40:59+00:00";
  condition = config.programs.awscli.enable && config.home.preferXdgDirectories;
  message = ''
    The `awscli` module now respects `config.home.preferXdgDirectories` when
    installing your configuration and credentials files.

    Previously, these files were always installed to `~/.aws/config` and
    `~/.aws/credentials`. Now, they will be installed to
    `${config.xdg.configHome}/aws/config` and
    `${config.xdg.configHome}/aws/credentials` if you have
    `config.home.preferXdgDirectories` set to `true`.

    The `AWS_CONFIG_FILE` and `AWS_SHARED_CREDENTIALS_FILE` session variables
    point the AWS CLI at the new locations, but only programs that source
    Home Manager's session variables will see them. Other tools that read
    AWS credentials directly, such as IDE plugins or SDKs, may stop finding
    your configuration after your next switch.
  '';
}
