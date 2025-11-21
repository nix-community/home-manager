{ pkgs, ... }:

{
  time = "2023-06-30T14:46:22+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.ssh-agent'
  '';
}
