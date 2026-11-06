{ config, ... }:
{
  time = "2026-08-27T12:00:00+00:00";
  condition =
    (config.nix.enable && config.nix.nixPath != [ ] && config.nix.keepOldNixPath)
    || config.xdg.systemDirs.config != [ ]
    || config.xdg.systemDirs.data != [ ];
  message = ''
    {env}`NIX_PATH`, {env}`XDG_CONFIG_DIRS`, and {env}`XDG_DATA_DIRS` are now
    declared through {option}`home.sessionSearchVariables` instead of a
    self-referential {option}`home.sessionVariables` value. The generated shell
    code expands to the same search path as before, and the
    {file}`environment.d` values for systemd user services are unchanged.

    One thing does change. A value assigned through
    {option}`home.sessionVariables.XDG_DATA_DIRS` (or the other two names) no
    longer conflicts with the module definition. It becomes the trailing value
    after the configured search entries. Plain list entries assigned through
    {option}`home.sessionSearchVariables.XDG_DATA_DIRS` stay ahead of the
    module entries.

    To replace the module's configured search entries while retaining the
    inherited value, use `lib.mkForce` on
    {option}`home.sessionSearchVariables.XDG_DATA_DIRS`. To keep the previous
    exact-value behavior, set the corresponding {option}`nix.nixPath`,
    {option}`xdg.systemDirs.config`, or {option}`xdg.systemDirs.data` list to
    empty, using `lib.mkForce [ ]` if other modules contribute values, and
    continue to use {option}`home.sessionVariables`. For the XDG names, the
    {file}`environment.d` output remains controlled separately by the
    corresponding {option}`xdg.systemDirs` list.
  '';
}
