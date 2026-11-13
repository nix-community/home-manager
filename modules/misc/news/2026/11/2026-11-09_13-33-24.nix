{ config, ... }:
{
  time = "2026-11-09T19:33:24+00:00";
  condition = config.programs.waveterm.enable;
  message = ''
    The `programs.waveterm.package` option now defaults to `null`.

    Nixpkgs removed the `waveterm` package because it depends on an
    end-of-life Electron release and has no maintainer in Nixpkgs. Home
    Manager still writes the Wave Terminal settings, themes, and bookmarks,
    but no longer installs Wave Terminal by default. Install it another way,
    or set `programs.waveterm.package` to a package that provides it.
  '';
}
