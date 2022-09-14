{ ... }:

{
  programs.micro = {
    enable = true;

    settings = {
      autosu = false;
      cursorline = false;
    };

    bindings = {
      Alt-d = "SpawnMultiCursor";
      Escape = "RemoveAllMultiCursors";
    };
  };

  test.stubs.micro = { };

  nmt.script = ''
     assertFileContent home-files/.config/micro/settings.json \
     ${
       builtins.toFile "micro-expected-settings.json" ''
         {
           "autosu": false,
           "cursorline": false
         }
       ''
     }
    assertFileContent home-files/.config/micro/bindings.json \
     ${
       builtins.toFile "micro-expected-settings.json" ''
         {
           "Alt-d": "SpawnMultiCursor",
           "Escape": "RemoveAllMultiCursors"
         }
       ''
     }
  '';
}
