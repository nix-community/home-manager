{
  programs.openstackclient = {
    enable = false;
    cloudsSettings.cache.expiration_time = 300;
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/openstack
  '';
}
