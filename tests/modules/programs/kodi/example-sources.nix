{ config, ... }:

{
  programs.kodi = {
    enable = true;
    package = config.lib.test.mkStubPackage { };

    sources = {
      video = {
        default = "movies";
        source = [
          {
            name = "videos";
            path = "/path/to/videos";
            allowsharing = "true";
          }
          {
            name = "movies";
            path = "/path/to/movies";
            allowsharing = "true";
          }
        ];
      };
    };

  };

  nmt.script = ''
    assertFileContent \
      home-files/.kodi/userdata/sources.xml \
      ${./example-sources-expected.xml}
  '';
}
