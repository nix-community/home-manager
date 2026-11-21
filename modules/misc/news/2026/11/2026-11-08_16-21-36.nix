{ config, ... }:
{
  time = "2026-11-08T16:21:36+00:00";
  condition = config.specialisation != { };
  message = ''
    The activation script now accepts the option '--files-only'. It places
    the generation's files and runs their 'onChange' hooks, but makes no
    Nix calls and leaves packages and services alone. Follow it with a
    full activation of the same generation, with no other activation in
    between. This applies, for example, a specialisation that only changes
    colors right away.

    Other activation blocks can join such a run through the new option
    'home.activationFilesOnly'.
  '';
}
