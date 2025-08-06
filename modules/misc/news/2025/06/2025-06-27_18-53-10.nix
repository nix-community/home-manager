{ config, ... }:

{
  time = "2025-06-27T18:53:10+00:00";
  condition = config.programs.ashell.enable && (config.programs.ashell.settings != { });
  message = ''
    ashell 0.5.0 changes the configuration file location and format.
    The camelCase format has been removed in favor of snake_case, which better aligns with the toml syntax.

    Your configuration will break if you have defined the "programs.ashell.settings" option.
    To resolve this, please alter your settings to use snake_case.
  '';
}
