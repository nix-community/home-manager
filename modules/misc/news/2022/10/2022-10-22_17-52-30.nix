{ config, ... }:

{
  time = "2022-10-22T17:52:30+00:00";
  condition = config.programs.firefox.enable;
  message = ''

    It is now possible to configure the default search engine in Firefox
    with

      programs.firefox.profiles.<name>.search.default

    and add custom engines with

      programs.firefox.profiles.<name>.search.engines.

    It is also recommended to set

      programs.firefox.profiles.<name>.search.force = true

    since Firefox will replace the symlink for the search configuration on
    every launch, but note that you'll lose any existing configuration by
    enabling this.
  '';
}
