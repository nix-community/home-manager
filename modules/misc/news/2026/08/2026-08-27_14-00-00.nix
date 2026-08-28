{
  time = "2026-08-27T14:00:00+00:00";
  condition = true;
  message = ''
    {file}`hm-session-vars.sh` now refreshes plain and search variables whenever
    a shell applies it. Zsh, Fish, and `targets.genericLinux.enable` startup
    paths pick up values changed by `home-manager switch` without logging out.
    Plain variables are re-evaluated and re-exported, while search variables
    add only missing entries. Shell expansions, including command
    substitutions, run again when the file is applied.

    Module-provided extra setup still runs once per session because it may
    contain arbitrary code.

    Self-referential values can change repeatedly. Removing a variable still
    requires a new session because Home Manager does not record what a previous
    generation exported.
  '';
}
