{ ... }:

{
  config = {
    programs.newsraft = {
      enable = true;

      feeds = [
        "https://nixos.org/blog/announcements-rss.xml"

        {
          name = "Tech";
          urls = [
            "https://news.ycombinator.com/rss"
            "https://www.phoronix.com/rss.php"
          ];
        }
      ];

      settings = {
        scrolloff = 12;
        copy-to-clipboard-command = "wl-copy";
        section-menu-paramount-explore = true;

        color-status-good-fg = "default";
        color-status-good-bg = "bold green";
      };

      bindings = {
        f = "exec feh %l";
        "^P" = "mark-unread-all";
      };

      extraConfig = "unbind r";
    };

    test.stubs.newsraft = { };

    nmt.script = ''
      assertFileContent \
        home-files/.config/newsraft/feeds \
        ${./newsraft-feeds}

      assertFileContent \
        home-files/.config/newsraft/config \
        ${./newsraft-settings}
    '';
  };
}
