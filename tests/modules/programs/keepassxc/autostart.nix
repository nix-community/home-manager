{
  programs.keepassxc = {
    enable = true;
    autostart = true;
  };
  xdg.autostart.enable = false;

  test.asserts.assertions.expected = [
    ''
      {option}`xdg.autostart.enable` has to be enabled in order for
      {option}`programs.keepassxc.autostart` to be effective.
    ''
  ];
}
