{ ... }:

{
  services.local-ai.enable = true;

  nmt.script = ''
    assertFileExists home-files/.config/systemd/user/local-ai.service
  '';
}
