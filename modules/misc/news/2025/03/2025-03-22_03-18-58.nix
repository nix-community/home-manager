{ pkgs, ... }:

{
  time = "2025-03-22T03:18:58+00:00";
  condition = pkgs.stdenv.hostPlatform.isDarwin;
  message = ''
    A new module is available: 'services.skhd'.

    Simple Hotkey Daemon (skhd) is a simple macOS hotkey daemon that allows
    defining system-wide keyboard shortcuts for launching applications and 
    shell commands. The module enables configuration of key combinations, modifiers,
    and associated actions, and integrates well with window managers like yabai.
  '';
}
