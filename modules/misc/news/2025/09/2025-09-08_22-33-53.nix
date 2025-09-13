{ config, ... }:
{
  time = "2025-09-09T05:33:53+00:00";
  condition = config.programs.kitty.enable;
  message = ''
    Kitty 0.42 adds a quick access terminal that appears and disappears with a key press.

    You can now configure this with 'programs.kitty.quickAccessTerminalConfig'.
  '';
}
