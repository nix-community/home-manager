{
  time = "2026-01-19T05:36:20+00:00";
  condition = true;
  message = ''
    Chrome now has a `plasmaSupport` flag.

    If you use KDE Plasma, set:

    ```
    programs.google-chrome.plasmaSupport = true`
    home.sessionVariables = [
      QT_QPA_PLATFORMTHEME = "kde";
    ];
    ```

    This enables the "Use QT" theme in **Settings > Appearance**, which makes
    Chrome match your Plasma theme.
  '';
}
