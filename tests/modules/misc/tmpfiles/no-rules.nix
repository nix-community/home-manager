{
  imports = [ ./common-stubs.nix ];

  systemd.user.tmpfiles.settings = { };

  nmt.script = ''
    assertPathNotExists home-files/.config/user-tmpfiles.d/
  '';
}
