{
  programs.telegram.enable = false;

  nmt.script = ''
    assertPathNotExists home-files/.local/share/TelegramDesktop
  '';
}
