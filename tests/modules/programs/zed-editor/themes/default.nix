{ config, ... }:
{
  programs.zed-editor = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
    themes = {
      path = ./one.json;
      string = builtins.readFile ./one.json;
      json = builtins.fromJSON (builtins.readFile ./one.json);
    };
  };

  nmt.script = toString (
    map
      (theme: ''
        assertFileExists "home-files/.config/zed/themes/${theme}.json"
        assertFileContent "home-files/.config/zed/themes/${theme}.json" "${./one.json}"
      '')
      [
        "path"
        "string"
        "json"
      ]
  );
}
