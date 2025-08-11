{ pkgs, ... }:

{
  time = "2023-07-25T07:16:09+00:00";
  condition = pkgs.stdenv.hostPlatform.isDarwin;
  message = ''

    The 'services.git-sync' module is now available on Darwin/macOS.
  '';
}
