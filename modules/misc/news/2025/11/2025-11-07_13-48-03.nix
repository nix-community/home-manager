{
  time = "2025-11-07T13:48:03+00:00";
  condition = true;
  message = ''
    The atuin module now always generates a configuration file at
    '~/.config/atuin/config.toml', even when 'programs.atuin.settings' is empty.

    This prevents atuin from automatically writing its default config file
    which would cause home-manager to fail when users later add settings
    to their configuration.

    This is a breaking change: if you currently have atuin enabled with empty
    settings and atuin has already created a configuration file, you may need to
    remove the existing file before your next home-manager switch:

      rm ~/.config/atuin/config.toml

    After this, home-manager will manage the configuration file going forward.
  '';
}
