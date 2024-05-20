{ config, pkgs, ... }:

{
  programs.freetube = {
    enable = true;
    settings = {
      useRssFeeds = true;
      hideHeaderLogo = true;
      allowDashAv1Formats = true;
      commentAutoLoadEnabled = true;

      checkForUpdates = false;
      checkForBlogPosts = false;

      listType = "list";
      defaultQuality = "1080";
    };
  };

  test.stubs.freetube = { };

  nmt.script = ''
    assertFileExists home-files/.config/FreeTube/hm_settings.db
    assertFileContent home-files/.config/FreeTube/hm_settings.db \
      ${./basic-configuration.db}

    assertFileContains activate \
      "install -Dm644 \$VERBOSE_ARG '/home/hm-user/.config/FreeTube/hm_settings.db' '/home/hm-user/.config/FreeTube/settings.db'"
  '';
}
