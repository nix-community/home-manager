{
  programs.rofi = {
    enable = true;

    pass = {
      enable = true;
      stores = [ "~/.local/share/password-store" ];
    };
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/rofi-pass/config \
      ${
        builtins.toFile "rofi-pass-expected-config" ''
          root=~/.local/share/password-store
        ''
      }
  '';
}
