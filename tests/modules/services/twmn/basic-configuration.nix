{
  config = {
    services.twmn = {
      enable = true;
      duration = 4242;
      host = "example.com";
      port = 9006;
      screen = 0;
      soundCommand = "/path/sound/command";
      icons.critical = "/path/icon/critical";
      icons.info = "/path/icon/info";
      icons.warning = "/path/icon/warning";
      text = {
        color = "#FF00FF";
        font.family = "Noto Sans";
        font.size = 16;
        font.variant = "italic";
        maxLength = 80;
      };
      window = {
        alwaysOnTop = true;
        color = "black";
        height = 20;
        offset.x = 20;
        offset.y = -60;
        opacity = 80;
        position = "center";
        animation = {
          easeIn.curve = 27;
          easeIn.duration = 314;
          easeOut.curve = 13;
          easeOut.duration = 168;
          bounce.enable = true;
          bounce.duration = 271;
        };
      };
    };

    test.stubs.twmn = { };

    nmt.script = ''
      serviceFile="home-files/.config/systemd/user/twmnd.service"
      assertFileExists "$serviceFile"
      assertFileRegex "$serviceFile" 'X-Restart-Triggers=.*twmn\.conf'
      assertFileRegex "$serviceFile" 'ExecStart=@twmn@/bin/twmnd'
      assertFileExists "home-files/.config/twmn/twmn.conf"
      assertFileContent "home-files/.config/twmn/twmn.conf" \
          ${./basic-configuration.conf}
    '';
  };
}
