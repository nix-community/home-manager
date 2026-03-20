{ pkgs, ... }:

{
  time = "2023-03-25T11:03:24+00:00";
  condition = pkgs.stdenv.hostPlatform.isDarwin;
  message = ''

    A new module is available: 'services.syncthing'.
  '';
}
