lib:
lib.mkOption {
  type = lib.types.attrs;
  default = { };
  example = { "filemanager-showdotfiles" = true; };
  description = ''
    Set extra settings, e.q. for plugins, that are not yet known in settings.
  '';
}
