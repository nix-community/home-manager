{ config, ... }:
{
  time = "2026-10-24T10:00:00+00:00";
  condition = config.programs.opencode.enable;
  message = ''
    The OpenCode module now supports the OpenCode 2 shared background
    service through `programs.opencode.service`.

    When enabled, Home Manager merges the declared service settings into
    `$XDG_CONFIG_HOME/opencode/service.json` during activation instead of
    linking it. Values not declared here are preserved, so passwords and
    remote routes created by OpenCode survive. Home Manager never starts the
    service, but restarts a running service when its configuration changes.
    Set `programs.opencode.service.settings.disabled` to stop a running
    service.

    Use `programs.opencode.service.passwordFile` to provide the service
    password from a secret manager and
    `programs.opencode.service.environmentFile` for environment variables.
  '';
}
