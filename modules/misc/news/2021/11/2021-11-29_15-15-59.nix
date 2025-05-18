{ pkgs, ... }:

{
  time = "2021-11-29T15:15:59+00:00";
  condition = pkgs.stdenv.hostPlatform.isDarwin;
  message = ''

    The option 'targets.darwin.defaults."com.apple.menuextra.battery".ShowPercent'
    has been deprecated since it no longer works on the latest version of
    macOS.
  '';
}
