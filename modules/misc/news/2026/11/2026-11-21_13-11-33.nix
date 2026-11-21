{ config, ... }:
{
  time = "2026-11-21T12:11:33+00:00";
  condition = config.programs.ortie.enable;
  message = ''
    The 'programs.ortie' module now targets Ortie 3, which brings breaking
    changes to its configuration.

    Ortie 3 refuses the `hooks` table of an account in
    {option}`programs.ortie.settings`: chain the command a hook ran after
    `storage.write.command` instead, which receives the token on every
    issue and refresh, for example:

    ```nix
    programs.ortie.settings.accounts.personal.storage.write.command =
      "pass insert -m -f ortie/personal && logger 'ortie stored a token'";
    ```

    See the migration guide at
    https://github.com/pimalaya/ortie/blob/v3.0.0/MIGRATION.md for the other
    changes, such as `tls` becoming a table.
  '';
}
