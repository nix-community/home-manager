{ pkgs, ... }:

{
  time = "2025-02-22T16:46:56+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'services.wpaperd'.

    This replaces the existing module, 'programs.wpaperd', and adds a
    systemd service to ensure its execution.
  '';
}
