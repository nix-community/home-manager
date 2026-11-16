{ realPkgs, ... }:

{
  services.openlinkhub = {
    enable = true;

    memory = {
      enable = true;
      sku = null;
      smb = null;
      type = null;
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

  test.asserts.assertions.expected =
    let
      assertMemoryOptionNotNull = opt: ''
        The option `services.openlinkhub.memory.${opt}` must not be null when
        `services.openlinkhub.memory.enable` is set to true.
      '';
    in
    [
      (assertMemoryOptionNotNull "sku")
      (assertMemoryOptionNotNull "smb")
      (assertMemoryOptionNotNull "type")
    ];
}
