{
  config,
  ...
}:
{
  time = "2026-10-03T09:43:05+00:00";
  condition = config.programs.tea.enable;
  message = ''
    A new module is available: `programs.tea`.

    `tea` is the CLI for Gitea and Forgejo. The module adds a typed
    `programs.tea.logins` option that generates
    {file}`$XDG_CONFIG_HOME/tea/config.yml`, including SSH login settings
    and preferences. Logins can use `token` or `tokenFile`; when
    `tokenFile` is used the generated file contains a placeholder that an
    activation script replaces with the file contents at activation
    time, keeping the secret out of the Nix store.
  '';
}
