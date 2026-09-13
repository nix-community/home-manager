{ config, ... }:
{
  time = "2026-09-11T00:00:00+00:00";
  condition = config.programs.openstackclient.enable;
  message = ''
    OpenStackClient now supports complete configuration documents through
    `programs.openstackclient.cloudsSettings` and
    `programs.openstackclient.cloudsPublicSettings`. These options allow root
    settings such as `cache` and `client` alongside cloud definitions.
  '';
}
