let
  fcConfD = "home-files/.config/fontconfig/conf.d";
in
{
  home.stateVersion = "25.11"; # <= 26.05

  fonts.fontconfig = {
    enable = true;
    configFile.implicitly-disabled.text = "foo";
  };

  nmt.script = ''
    assertFileExists ${fcConfD}/10-hm-fonts.conf
    assertFileExists ${fcConfD}/52-hm-default-fonts.conf

    assertPathNotExists ${fcConfD}/90-hm-implicitly-disabled.conf
  '';
}
