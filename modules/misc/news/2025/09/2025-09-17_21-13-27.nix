{ pkgs, ... }:

{
  time = "2025-09-18T00:13:27+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: `programs.formiko`

    Formiko is reStructuredText and MarkDown editor and live previewer.
    It is written in Python with Gtk3, GtkSourceView and Webkit2.
    Use Docutils and MarkDown to reStructuredText covertor.
  '';
}
