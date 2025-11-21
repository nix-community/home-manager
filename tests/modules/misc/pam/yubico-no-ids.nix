{
  config = {
    nmt.script = ''
      assertPathNotExists home-files/.yubico/authorized_yubikeys
    '';
  };
}
