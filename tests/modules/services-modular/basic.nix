{ pkgs, ... }:
{
  home.services.demo = {
    process.argv = [
      "${pkgs.coreutils}/bin/echo"
      "hello"
    ];
  };

  nmt.script = ''
    assertFileExists home-files/.config/systemd/user/demo.service
    assertFileContains home-files/.config/systemd/user/demo.service '/bin/echo'
    assertFileContains home-files/.config/systemd/user/demo.service 'WantedBy=default.target'
  '';
}
