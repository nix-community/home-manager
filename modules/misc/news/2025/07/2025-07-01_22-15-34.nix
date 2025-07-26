{ pkgs, ... }:
{
  time = "2025-07-01T20:15:34+00:00";
  condition = pkgs.stdenv.hostPlatform.isDarwin;
  message = ''
    XML characters are escaped for 'targets.darwin.keybindings' and 'launchd.agents.<name>'.

    Special characters used in strings passed to  'targets.darwin.keybindings'
    and 'launchd.agents.<name>' are now escaped before being included in the
    generated plist files. If you were doing manual escaping you will need to
    stop to avoid double escaping.
  '';
}
