{ config, ... }:
{
  time = "2026-02-13T20:17:15+00:00";
  condition = config.programs.yazi.enable;
  message = "
      The option `programs.yazi.shellWrapperName` default has changed from `yy` to `y`
      to align with the recommendation from upstream.
    ";
}
