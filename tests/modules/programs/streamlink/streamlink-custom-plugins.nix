{ pkgs, ... }:

{
  programs.streamlink = {
    enable = true;
    plugins = {
      dummy.src = ./dummy.py;

      dummy2.src = builtins.readFile ./dummy.py;

      twitch.settings = {
        player = "haruna";
        quiet = true;
      };
    };
  };

  test.stubs.streamlink = { };

  nmt.script =
    let
      configDir =
        if pkgs.stdenv.isDarwin then "Library/Application Support/streamlink" else ".config/streamlink";

      pluginDir =
        if pkgs.stdenv.isDarwin then
          "Library/Application Support/streamlink/plugins"
        else
          ".local/share/streamlink/plugins";
    in
    ''
      assertFileExists "home-files/${configDir}/config.twitch"
      assertFileContent "home-files/${configDir}/config.twitch" ${pkgs.writeText "expected" ''
        player=haruna
        quiet
      ''}

      assertFileExists "home-files/${pluginDir}/dummy.py"
      assertFileContent "home-files/${pluginDir}/dummy.py" ${./dummy.py}

      assertFileExists "home-files/${pluginDir}/dummy2.py"
      assertFileContent "home-files/${pluginDir}/dummy2.py" ${./dummy.py}
    '';
}
