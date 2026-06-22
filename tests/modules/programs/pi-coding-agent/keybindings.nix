{
  programs.pi-coding-agent = {
    enable = true;
    keybindings = {
      "tui.editor.cursorUp" = [
        "up"
        "ctrl+p"
      ];
      "tui.editor.cursorDown" = [
        "down"
        "ctrl+n"
      ];
      "tui.editor.deleteWordBackward" = [
        "ctrl+w"
        "alt+backspace"
      ];
    };
  };
  nmt.script = ''
    assertFileExists home-files/.pi/agent/keybindings.json
    assertFileContent home-files/.pi/agent/keybindings.json \
      ${./keybindings.json}
  '';
}
