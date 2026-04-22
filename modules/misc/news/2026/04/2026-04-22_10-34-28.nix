{
  time = "2026-04-22T10:34:28+00:00";
  condition = true;
  message = ''
    Google Chrome browser modules now support `extensions` on Darwin.

    Home Manager now installs Chrome Web Store extension metadata for:

    - `programs.google-chrome`
    - `programs.google-chrome-beta`
    - `programs.google-chrome-dev`

    Home Manager now also raises a clear assertion if you try to manage
    Google Chrome extensions on Linux, since Chrome only supports those from
    system-managed directories there.
  '';
}
