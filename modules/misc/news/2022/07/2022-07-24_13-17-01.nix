{ pkgs, ... }:

{
  time = "2022-07-24T13:17:01+00:00";
  condition = pkgs.stdenv.hostPlatform.isDarwin;
  message = ''

    A new option is available: 'targets.darwin.currentHostDefaults'.

    This exposes macOS preferences that are available through the
    'defaults -currentHost' command.
  '';
}
