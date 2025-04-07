{
  programs.aerospace = {
    enable = true;
    userSettings = {
      gaps = {
        outer.left = 8;
        outer.bottom = 8;
        outer.top = 8;
        outer.right = 8;
      };
      mode.main.binding = {
        alt-h = "focus left";
        alt-j = "focus down";
        alt-k = "focus up";
        alt-l = "focus right";
      };
      on-window-detected = [
        {
          "if" = {
            app-id = "com.apple.MobileSMS";
          };
          run = [ "move-node-to-workspace 10" ];
        }
        {
          "if" = {
            app-id = "ru.keepcoder.Telegram";
          };
          run = [ "move-node-to-workspace 10" ];
        }
        {
          "if" = {
            app-id = "org.whispersystems.signal-desktop";
          };
          run = [ "move-node-to-workspace 10" ];
        }
      ];
    };
  };

  nmt.script = ''
    assertFileContent home-files/.config/aerospace/aerospace.toml ${./settings-expected.toml}
  '';
}
