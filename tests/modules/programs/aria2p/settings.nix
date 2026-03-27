{
  programs.aria2p = {
    enable = true;
    settings = {
      key_bindings = {
        AUTOCLEAR = "c";
        FILTER = [
          "F4"
          "\\"
        ];
      };
      colors = {
        UI = "WHITE BOLD DEFAULT";
        FOCUSED_HEADER = "BLACK NORMAL CYAN";
        METADATA = "WHITE UNDERLINE DEFAULT";
      };
    };
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/aria2p/config.toml \
      ${builtins.toFile "aria2p-expected-config.toml" ''
        [colors]
        FOCUSED_HEADER = "BLACK NORMAL CYAN"
        METADATA = "WHITE UNDERLINE DEFAULT"
        UI = "WHITE BOLD DEFAULT"

        [key_bindings]
        AUTOCLEAR = "c"
        FILTER = ["F4", "\\"]
      ''}
  '';
}
