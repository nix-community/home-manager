{ pkgs, ... }:
{
  time = "2025-09-08T18:49:30+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'programs.radicle'.
    A new service is available: 'services.radicle.node'.

    Radicle is a distributed code forge built on Git.
    Since it is possible to interact with Radicle storage without running the service, two modules were introduced.
  '';
}
