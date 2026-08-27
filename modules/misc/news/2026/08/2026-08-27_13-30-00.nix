{ pkgs, ... }:
{
  time = "2026-08-27T13:30:00+00:00";
  condition = pkgs.stdenv.hostPlatform.isDarwin;
  message = ''
    On Darwin, {env}`TERMINFO_DIRS` is now built from
    {option}`home.sessionSearchVariables` and
    {option}`home.sessionSearchVariablesAppend` instead of a single
    self-referential {option}`home.sessionVariables` value. On the first merge,
    Home Manager's directory comes first and {file}`/usr/share/terminfo` comes
    last, with inherited directories kept between them and without duplicating
    configured entries. Later merges preserve the positions of configured
    entries already present in {env}`TERMINFO_DIRS`.

    This retires the opt-out described in the 2026-04-20 news entry. Overriding
    {option}`home.sessionVariables.TERMINFO_DIRS` no longer replaces Home
    Manager's value, and it does so quietly rather than failing, because the
    module no longer defines that name.

    Use {option}`targets.darwin.terminfo.enable` `= false` to manage the
    variable yourself, or add your own entries to
    {option}`home.sessionSearchVariables.TERMINFO_DIRS`, which compose with
    Home Manager's.
  '';
}
