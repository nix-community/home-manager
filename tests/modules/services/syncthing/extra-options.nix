{ config, ... }:

{
  services.syncthing = {
    enable = true;
    extraOptions = [ "-foo" ''-bar "baz"'' ];
  };

  test.stubs.syncthing = { };

  nmt.script = ''
    assertFileExists home-files/.config/systemd/user/syncthing.service
    assertFileContains home-files/.config/systemd/user/syncthing.service \
      "ExecStart=@syncthing@/bin/syncthing -no-browser -no-restart -logflags=0 '-foo' '-bar \"baz\"'"
  '';
}
