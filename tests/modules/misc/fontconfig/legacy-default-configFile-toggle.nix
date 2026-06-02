let
  fcConfD = "home-files/.config/fontconfig/conf.d";
in
{
  home.stateVersion = "26.05"; # <= 26.11

  fonts.fontconfig = {
    enable = true;
    configFile.implicitly-disabled.text = "foo";
  };

  asserts.warning.expected = [
    ''
      The default value of `fonts.fontconfig.configFile.implicitly-disabled.enable` has changed from `false` to `true`.
      You are currently using the legacy default (`false`) because `home.stateVersion` is less than "26.11".
      To silence this warning and keep legacy behavior, set:
        fonts.fontconfig.configFile.implicitly-disabled.enable = false;
      To adopt the new default behavior, set:
        fonts.fontconfig.configFile.implicitly-disabled.enable = true;
    ''
  ];

  nmt.script = ''
    assertFileExists ${fcConfD}/10-hm-fonts.conf
    assertFileExists ${fcConfD}/52-hm-default-fonts.conf

    assertPathNotExists ${fcConfD}/90-hm-implicitly-disabled.conf
  '';
}
