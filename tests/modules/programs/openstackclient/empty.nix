{
  programs.openstackclient = {
    enable = true;
    package = null;
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/openstack
  '';
}
