{ pkgs, ... }:
{
  time = "2026-08-31T00:44:25+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    The `xdg.mimeApps` options `defaultApplications`, `associations.added`, and
    `associations.removed` now support glob keys.

    Keys ending in `*` are treated as prefix globs. They are expanded against
    all MIME types known to the shared-mime-info database before being written
    to `mimeapps.list`. Exact keys take precedence over glob matches, e.g.:

    ```nix
    xdg.mimeApps.defaultApplications = {
      "text/*" = "editor.desktop";
      "text/html" = "browser.desktop";
    };
    ```
  '';
}
