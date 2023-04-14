{ ... }:

{
  services.comodoro = {
    enable = true;
    preset = "preset";
    protocols = [ "tcp" ];
  };

  test.stubs.comodoro = { };

  nmt.script = ''
    serviceFile=$(normalizeStorePaths home-files/.config/systemd/user/comodoro.service)
    assertFileContent "$serviceFile" ${./expected.service}
  '';
}
