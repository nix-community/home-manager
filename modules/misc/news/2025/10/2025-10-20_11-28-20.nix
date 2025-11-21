{ pkgs, ... }:

{
  time = "2025-10-20T10:28:20+00:00";
  condition = pkgs.stdenv.hostPlatform.isDarwin;
  message = ''
    A new module is available: `targets.darwin.copyApps`.

    This is an alternative implementation of `targets.darwin.linkApps` that
    copies the app instead of symlinking. While this is less efficient and
    slower, it has the advantage that it works with macOS features like
    Spotlight. Hence it will be enabled by default if you're using
    `home.stateVersion >= "25.11"`.
  '';
}
