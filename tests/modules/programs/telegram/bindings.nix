{
  programs.telegram = {
    enable = true;
    bindings = [
      {
        command = "previous_chat";
        keys = "alt+k";
      }
      {
        command = "next_chat";
        keys = "alt+j";
      }
      {
        command = "search";
        keys = "alt+/";
      }
    ];
  };

  nmt.script = ''
    assertFileExists home-files/.local/share/TelegramDesktop/tdata/shortcuts-custom.json

    assertFileContent\
      home-files/.local/share/TelegramDesktop/tdata/shortcuts-custom.json\
      ${./bindings.json}
  '';
}
