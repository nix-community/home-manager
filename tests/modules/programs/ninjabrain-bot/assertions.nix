{
  programs.ninjabrain-bot = {
    enable = true;
    settings.overlayAutoHide = true;
  };

  test.asserts.assertions.expected = [
    "programs.ninjabrain-bot.settings.overlayAutoHide requires useObsOverlay = true."
  ];
}
