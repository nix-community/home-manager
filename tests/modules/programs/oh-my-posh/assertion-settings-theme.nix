{
  programs.oh-my-posh = {
    enable = true;
    settings = {
      version = 2;
    };
    useTheme = "jandedobbeleer";
  };

  test.asserts.assertions.expected = [
    "oh-my-posh: Only one of 'settings', 'useTheme', or 'configFile' can be configured at a time."
  ];
}
