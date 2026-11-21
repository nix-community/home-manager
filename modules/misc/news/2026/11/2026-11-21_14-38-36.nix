{ config, ... }:
{
  time = "2026-11-21T14:38:36+00:00";
  condition = config.programs.comodoro.enable || config.services.comodoro.enable;
  message = ''
    The 'programs.comodoro' and 'services.comodoro' modules now target
    Comodoro 3, which brings breaking changes to its configuration and its
    protocol.

    In {option}`programs.comodoro.settings`, the per-second hook
    `on-<cycle>-running` is now `on-<cycle>-tick`, and a notification is a
    template filled with `$cycleName` and `$cycleDuration`, so a literal `$`
    is written `$$`. A hook name no event fires, several accounts marked
    `default` and a cycle key other than `name` and `duration` are refused,
    for example:

    ```nix
    programs.comodoro.settings.accounts.pomodoro.hooks.on-work-end.notify.summary =
      "$cycleName ended";
    ```

    The timer server speaks a new protocol: restart any `comodoro watch`
    running outside the service. See the migration guide at
    https://github.com/pimalaya/comodoro/blob/v3.0.0/MIGRATION.md for the
    other changes.
  '';
}
