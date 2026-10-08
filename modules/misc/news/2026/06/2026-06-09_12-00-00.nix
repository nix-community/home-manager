{ config, ... }:
{
  time = "2026-06-09T12:00:00+00:00";
  condition = config.programs.kiro-cli.enable;
  message = ''
    A new module is available: `programs.kiro-cli`.

    It installs the kiro-cli package and provides optional shell
    integration for Bash and Zsh.
  '';
}
