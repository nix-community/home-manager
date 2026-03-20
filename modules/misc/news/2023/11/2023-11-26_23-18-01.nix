{ pkgs, ... }:

{
  time = "2023-11-26T23:18:01+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.signaturepdf'.
  '';
}
