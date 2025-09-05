{
  programs.yofi = {
    enable = true;
    settings = {
      width = 400;
      height = 512;
      force_window = false;
      corner_radius = "0";
      font_size = 24;
      bg_color = "0x272822ee";
      bg_border_color = "0x131411ff";
      input_text = {
        font_color = "0xf8f8f2ff";
        bg_color = "0x75715eff";
        margin = "5";
        padding = "1.7 -4";
      };
    };

    blacklist = [
      "firefox"
      "librewolf"
      "com.obsproject.Studio"
      "com.rtosta.zapzap"
      "cups"
      "kitty-open"
      "nvim"
    ];
  };

  nmt.script = ''
    assertFileExists home-files/.config/yofi/yofi.config
    assertFileExists home-files/.config/yofi/blacklist

    assertFileContent home-files/.config/yofi/yofi.config \
    ${./yofi.config}

    assertFileContent home-files/.config/yofi/blacklist \
    ${./blacklist}
  '';
}
