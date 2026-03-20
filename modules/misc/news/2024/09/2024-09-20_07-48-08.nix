{ config, pkgs, ... }:

{
  time = "2024-09-20T07:48:08+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux && config.services.swayidle.enable;
  message = ''

    The swayidle module behavior has changed. Specifically, swayidle was
    previously always called with a `-w` flag. This flag is now moved to
    the default `services.swayidle.extraArgs` value to make it optional.

    Your configuration may break if you already set this option and also
    rely on the flag being automatically added. To resolve this, please
    add `-w` to your assignment of `services.swayidle.extraArgs`.
  '';
}
