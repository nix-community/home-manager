{
  programs.zapzap = {
    enable = true;
    settings = {
      notification.donation_message = true;
      website.open_page = false;
      system = {
        scale = 150;
        theme = "dark";
        wayland = true;
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/ZapZap/ZapZap.conf
    assertFileContent home-files/.config/ZapZap/ZapZap.conf \
      ${./ZapZap.conf}
  '';
}
