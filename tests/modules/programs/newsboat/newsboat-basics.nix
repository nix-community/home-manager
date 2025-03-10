{
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

  nmt.script = ''
    assertFileContent \
      home-files/.newsboat/urls \
      ${./newsboat-basics-urls.txt}
  '';
}
