{
  time = "2025-11-26T10:55:28+00:00";
  condition = true;
  message = ''
    The option 'gtk.theme' does not apply to GTK 4 automatically anymore for new
    installations (with `home.stateVersion` >= "26.05"). Using a custom theme is
    not officially supported by GTK 4, and implemented by home-manager using a
    workaround that may cause issues in some cases. If you still want to use a GTK
    4 theme, you need to explicitly set 'gtk.gtk4.theme'.
  '';
}
