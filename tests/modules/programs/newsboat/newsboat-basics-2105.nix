{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    home.stateVersion = "21.05";

    programs.newsboat = {
      enable = true;

      urls = [
        {
          url = "http://example.org/feed.xml";
          tags = [ "tag1" "tag2" ];
          title = "Cool feed";
        }

        { url = "http://example.org/feed2.xml"; }
      ];

      queries = { "foo" = ''rssurl =~ "example.com"''; };
    };

    test.stubs.newsboat = { };

    # The format didn't change since 20.03, just the location.
    nmt.script = ''
      assertFileContent \
        home-files/.config/newsboat/urls \
        ${./newsboat-basics-urls-2003.txt}
    '';
  };
}
