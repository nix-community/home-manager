{ config, pkgs, ... }:

{
  time = "2025-12-23T11:10:24+00:00";
  condition = config.services.ssh-agent.enable && pkgs.stdenv.hostPlatform.isDarwin;
  message = ''
    A new option 'services.ssh-agent.forceOverride' has been added. When
    enabled, this option unconditionally sets the 'SSH_AUTH_SOCK' environment
    variable, overriding any existing value.

    This is particularly useful on macOS where the system's ssh-agent sets
    'SSH_AUTH_SOCK' by default, preventing Home Manager's ssh-agent from being
    used. On macOS, 'forceOverride' defaults to 'true'; on Linux it defaults to
    'false' to preserve the previous behavior.
  '';
}
