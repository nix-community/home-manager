{ pkgs, ... }:
{
  time = "2026-08-31T00:44:25+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    The `xdg.mimeApps` options `defaultApplications`, `associations.added`, and
    `associations.removed` now support glob keys.

    A key ending in `*` expands against all MIME types known to
    shared-mime-info, and exact keys take precedence over glob matches, e.g.:

    ```nix
    xdg.mimeApps.defaultApplications = {
      "text/*" = "editor.desktop";
      "text/html" = "browser.desktop";
    };
    ```
  '';
}
