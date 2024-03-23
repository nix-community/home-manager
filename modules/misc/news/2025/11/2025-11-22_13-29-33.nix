{ pkgs, ... }:

{
  time = "2025-11-22T13:29:33+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'services.secret-service'.
  '';
}
