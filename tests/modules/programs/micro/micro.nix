{ ... }:

{
  programs.micro = {
    enable = true;

    settings = {
      autosu = false;
      cursorline = false;
    };

    keybinds = {
      "Ctrl-y" = "Undo";
      "Ctrl-z" = "Redo";
    };
  };

  test.stubs.micro = { };

  nmt.script = ''
    assertFileContent home-files/.config/micro/settings.json \
    ${builtins.toFile "micro-expected-settings.json" ''
      {
        "autosu": false,
        "cursorline": false
      }
    ''}

    assertFileContent home-files/.config/micro/bindings.json \
    ${builtins.toFile "micro-expected-keybinds.json" ''
      {
        "Ctrl-y": "Undo",
        "Ctrl-z": "Redo"
      }
    ''}
  '';
}
