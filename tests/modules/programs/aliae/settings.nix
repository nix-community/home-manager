{
  programs.aliae = {
    enable = true;
    settings = {
      alias = [
        {
          name = "a";
          value = "aliae";
        }
        {
          name = "hello-world";
          value = ''echo "hello world"'';
          type = "function";
        }
      ];

      env = [
        {
          name = "EDITOR";
          value = "code-insiders --wait";
        }
      ];
    };
  };

  nmt.script = ''
    assertFileExists home-files/.aliae.yaml
    assertFileContent home-files/.aliae.yaml ${./aliae.yaml}
  '';
}
