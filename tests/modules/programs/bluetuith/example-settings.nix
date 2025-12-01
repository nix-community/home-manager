{
  programs.bluetuith = {
    enable = true;

    settings = {
      adapter = "hci0";
      receive-dir = "/home/user/files";

      keybindings = {
        Menu = "Alt-m";
      };

      theme = {
        Adapter = "red";
      };
    };
  };

  nmt.script = ''
    assertFileContent \
      "home-files/.config/bluetuith/bluetuith.conf" \
      ${./expected-settings-output.conf}
  '';

}
