{
  services.grobi = {
    enable = false;
    settings = throw "disabled Grobi settings were evaluated";
  };

  test.asserts.warnings.expected = [ ];

  nmt.script = ''
    assertPathNotExists home-files/.config/grobi.conf
    assertPathNotExists home-files/.config/systemd/user/grobi.service
  '';
}
