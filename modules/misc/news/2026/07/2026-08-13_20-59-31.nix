{ pkgs, ... }: {
  time = "2026-08-13T20:59:31+00:00";
  condition = pkgs.stdenv.hostPlatform.isDarwin;
  message = ''
    A lorri daemon for darwin is now available.

    Enable it with: `services.lorri.enable = true`
  '';
}
