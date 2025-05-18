{ pkgs, ... }:

{
  time = "2024-10-09T06:16:23+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.snixembed'.

    snixembed proxies StatusNotifierItems as XEmbedded systemtray-spec
    icons. This is useful for some tools in some environments, e.g., Safe
    Eyes in i3, lxde or mate.
  '';
}
