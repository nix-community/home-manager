{ config, ... }:

{
  time = "2025-10-27T10:57:29+00:00";
  condition = config.systemd.user.tmpfiles.rules != [ ];
  message = ''
    The 'systemd.user.tmpfiles' module now provides the option
    'systemd.user.tmpfiles.rulesToPurgeOnChange' to define rules whose
    target files are purged when the rules change.
  '';
}
