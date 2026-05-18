{
  programs.inkscape = {
    enable = true;
    keymap = {
      keys = {
        "@name" = "default";
        bind = [
          {
            "@key" = "F2";
            "@action" = "node-tool";
            "@display" = "true";
          }
          {
            "@key" = "F1";
            "@action" = "select-tool";
            "@display" = "true";
          }
        ];
      };
    };
  };

  nmt.script = ''
    keysFile=home-files/.config/inkscape/keys/default.xml

    assertFileExists "$keysFile"
    assertFileContains "$keysFile" 'node-tool'
    assertFileContains "$keysFile" 'select-tool'
  '';
}
