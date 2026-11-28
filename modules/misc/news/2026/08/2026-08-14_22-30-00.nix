{ config, ... }:
{
  time = "2026-08-14T22:30:00+00:00";
  condition = config.programs.comodoro.enable || config.services.comodoro.enable;
  message = ''
    Comodoro has been updated to 2.0.0, which breaks both the
    configuration file and the command line. See the
    [upstream changelog](https://github.com/pimalaya/comodoro/blob/v2.0.0/CHANGELOG.md).

    In {option}`programs.comodoro.settings`, the `presets` table became
    `accounts`, so a preset named `pomodoro` is now written as
    `settings.accounts.pomodoro`. Within an account, `timer-precision`
    became `precision`, `hooks.<name>.cmd` became
    `hooks.<name>.command`, and the `preset` field naming predefined
    cycles is gone: write the `cycles` out, or generate them with
    `comodoro configure`. Accounts written against Comodoro 1.x keep
    `unix-socket` as an alias of the `socket` table.

    {option}`services.comodoro.preset` has been renamed to
    {option}`services.comodoro.account` and
    {option}`services.comodoro.protocols` to
    {option}`services.comodoro.transports`. Both are optional now: an
    unset account serves the one marked `default`, and unset transports
    serve the one the account marks as default.
  '';
}
