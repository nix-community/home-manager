{
  time = "2026-06-22T19:16:41+00:00";
  condition = true;
  message = ''
    A new {option}`programs.devenv` module has been added to Home Manager.

    devenv is a tool for fast, declarative, reproducible and composable
    developer environments using Nix. The module provides options to enable
    devenv and configure shell integration for Bash, Fish, Nushell, and Zsh.

    To use it, set {option}`programs.devenv.enable` to `true`. Shell
    integration is enabled by default for installed shells.
  '';
}
