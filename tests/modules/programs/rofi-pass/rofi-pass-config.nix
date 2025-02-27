{
  programs.rofi = {
    enable = true;

    pass = {
      enable = true;
      extraConfig = ''
        # Extra config for rofi-pass
        xdotool_delay=12
      '';
    };
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/rofi-pass/config \
      ${
        builtins.toFile "rofi-pass-expected-config" ''
          # Extra config for rofi-pass
          xdotool_delay=12

        ''
      }
  '';
}
