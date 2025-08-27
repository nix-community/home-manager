{
  time = "2025-08-25T20:07:31+00:00";
  condition = true;
  message = ''
      The `services.conky` module now supports running multiple instances. A new
    option, `services.conky.configs`, allows you to define a set of named
    Conky configurations. Each configuration can specify its own config
    file/text, package, and whether it should start automatically. The old
    `extraConfig` option is preserved for backwards compatibility.
  '';
}
