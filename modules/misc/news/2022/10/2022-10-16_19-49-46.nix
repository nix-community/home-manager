{ pkgs, ... }:

{
  time = "2022-10-16T19:49:46+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    Two new modules are available:

      - 'programs.borgmatic' and
      - 'services.borgmatic'.

    use the first to configure the borgmatic tool and the second if you
    want to automatically run scheduled backups.
  '';
}
