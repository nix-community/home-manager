{ pkgs, ... }:
{
  time = "2026-11-26T16:49:59+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux || pkgs.stdenv.hostPlatform.isDarwin;
  message = ''
    A new module is available: 'programs.zapfast'.

    ZapFast is a fast, lightweight native WhatsApp client.
  '';
}
