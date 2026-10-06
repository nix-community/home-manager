{ realPkgs, ... }:

{
  services.openlinkhub = {
    enable = true;

    settings = {
      enableGamepad = true;
    };
  };

  test.unstubs = [
    (_self: _super: {
      inherit (realPkgs)
        openlinkhub
        systemd
        ;
    })
  ];

  test.asserts.warnings.expected = [
    ''
      The option `services.openlinkhub.settings.enableGamepad` requires that
      OpenLinkHub have access to uinput devices, which may compromise system security.

      The Home Manager-supplied udev rule does not include this permission, and thus
      it is up to you to supply safe access.

      If provided, you can silence this warning by setting:
        services.openlinkhub.allowGamepad = true;
    ''
  ];
}
