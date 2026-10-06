{ pkgs, ... }:
{
  time = "2026-09-12T06:19:39+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: `services.openlinkhub`.

    OpenLinkHub is an open-source interface for iCUE LINK Hub and other Corsair
    AIOs and Hubs. Manage RGB lighting, fan speeds, and system metrics, as well
    as keyboards, mice, and headsets via a web dashboard.
  '';
}
