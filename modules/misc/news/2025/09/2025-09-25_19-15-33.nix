{ config, ... }:

{
  time = "2025-09-25T22:15:33+00:00";
  condition = config.programs.aichat.enable;
  message = ''
    A new option is available: `programs.aichat.agents`

    This option allows you to set agent-specific settings for aichat.
  '';
}
