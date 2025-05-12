{ pkgs, ... }:

{
  time = "2023-07-25T07:16:09+00:00";
  condition = pkgs.stdenv.hostPlatform.isDarwin;
  message = ''

    A new module is available: 'services.git-sync'.
  '';
}
