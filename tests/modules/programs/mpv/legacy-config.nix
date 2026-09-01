{
  lib,
  options,
  ...
}:
{
  programs.mpv = {
    enable = true;
    config = {
      force-window = true;
      ytdl-format = "bestvideo+bestaudio";
      cache-secs = 4000000;
    };
  };

  test.asserts.warnings.expected = [
    "The option `programs.mpv.config' defined in ${lib.showFiles options.programs.mpv.config.files} has been renamed to `programs.mpv.settings'."
  ];

  nmt.script = ''
    assertFileContent home-files/.config/mpv/mpv.conf ${
      builtins.toFile "legacy-config.expected" (
        lib.concatStringsSep "\n" [
          ""
          "cache-secs=%7%4000000"
          "force-window=%3%yes"
          "ytdl-format=%19%bestvideo+bestaudio"
          ""
          ""
          ""
        ]
      )
    }
  '';
}
