{ config, ... }:

{
  time = "2025-01-21T17:28:13+00:00";
  condition = with config.programs.yazi; enable && enableFishIntegration;
  message = ''
    Yazi's fish shell integration wrapper now calls the 'yazi' executable
    directly, ignoring any shell aliases with the same name.

    Your configuration may break if you rely on the wrapper calling a
    'yazi' alias.
  '';
}
