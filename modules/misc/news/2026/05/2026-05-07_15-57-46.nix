_: {
  time = "2026-05-07T15:57:46+00:00";
  condition = true;
  message = ''
    A new option is available: `programs.microsoft-edge`.

    Microsoft Edge is now supported by the Chromium-based browser module,
    sharing the same `commandLineArgs`, `extensions`, `dictionaries` and
    `nativeMessagingHosts` interface.

    Note: the `microsoft-edge` package in nixpkgs is only available on
    `x86_64-linux`. On macOS, install Edge through other means (e.g. the
    official `.pkg` installer) and set
    `programs.microsoft-edge.package = null` to manage configuration files
    only, or supply a custom darwin-compatible package.
  '';
}
