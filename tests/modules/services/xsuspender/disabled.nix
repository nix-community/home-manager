_:

{
  services.xsuspender = {
    enable = false;
    settings.Browser.match_wm_class_contains = "browser";
  };

  test.asserts.warnings.expected = [ ];

  nmt.script = ''
    assertPathNotExists home-files/.config/xsuspender.conf
    assertPathNotExists home-files/.config/systemd/user/xsuspender.service
  '';
}
