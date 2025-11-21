{ config, ... }:
{
  time = "2025-07-28T09:45:00+00:00";
  condition = config.programs.zsh.enable;
  message = ''
    The zsh module has been refactored to improve path handling.

    Previously, path resolution was inconsistent and relied on hardcoded
    `$HOME` references. The module has been restructured to use dedicated
    path handling functions that properly handle both absolute and relative
    paths while maintaining consistent behavior.

    As part of this refactoring, the use of relative paths has
    been deprecated. Users are encouraged to use absolute paths for more
    predictable path resolution.
  '';
}
