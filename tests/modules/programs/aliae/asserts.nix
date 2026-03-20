{
  programs.aliae = {
    enable = true;
    configLocation = "/another/path/aliae.yaml";
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

  test.asserts.assertions.expected = [
    "The option `programs.aliae.configLocation` must point to a file inside user's home directory when `programs.aliae.settings` is set."
  ];
}
