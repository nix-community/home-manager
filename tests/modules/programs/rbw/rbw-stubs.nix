{ config, ... }:

{
  test.stubs.rbw = { };

  nixpkgs.overlays = [
    (self: super: {
      pinentry-gnome3 =
        config.lib.test.mkStubPackage { outPath = "@pinentry-gnome3@"; };
    })
  ];
}
