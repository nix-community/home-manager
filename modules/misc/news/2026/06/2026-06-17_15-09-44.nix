{ pkgs, ... }:
{
  time = "2026-06-17T14:09:44+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: `services.nvibrant`.

    [nvibrant] is used for configuring NVIDIA's "Digital Vibrance" on Wayland.

    [nvibrant]: https://github.com/tremeschin/nvibrant
  '';
}
