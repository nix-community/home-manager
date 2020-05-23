{ config, lib, pkgs, ... }:

with lib;

{
  config = {
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

    nixpkgs.overlays = [
      (self: super: { newsboat = pkgs.writeScriptBin "dummy-newsboat" ""; })
    ];

    nmt.script = ''
      assertFileContent \
        $home_files/.newsboat/urls \
        ${./newsboat-basics-urls.txt}
    '';
  };
}
