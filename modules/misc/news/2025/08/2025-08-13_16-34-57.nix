{ pkgs, ... }:
{
  time = "2025-08-13T21:34:57+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'services.protonmail-bridge'.

    ProtonMail Bridge is a desktop application that runs in the background,
    encrypting and decrypting messages as they enter and leave your computer.
    It lets you add your ProtonMail account to your favorite email client via
    IMAP/SMTP by creating a local email server on your computer.
  '';
}
