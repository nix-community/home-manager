{ ... }:
{
  time = "2026-09-08T12:00:00+00:00";
  condition = true;
  message = ''
    `home.file.<name>.mutable` and `xdg.configFile.<name>.mutable` install
    writable copies of regular files instead of symbolic links.

    These copies remain owned by Home Manager: activation replaces application
    edits, and removing or disabling a declaration deletes its file. Existing
    unmanaged files require a backup or an explicit `force` setting. Stop the
    application before switching generations. Sources still enter the Nix
    store and must not contain secrets.
  '';
}
