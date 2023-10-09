{ config, ... }:

{
  programs.gnome-terminal = {
    enable = true;
    profile = {
      bad-name = { visibleName = "a"; };
      "e0b782ed-6aca-44eb-8c75-62b3706b6220" = {
        default = true;
        visibleName = "b";
      };
      another-bad-name = { visibleName = "c"; };
    };
  };

  nixpkgs.overlays = [
    (self: super: { gnome.gnome-terminal = config.lib.test.mkStubPackage { }; })
  ];

  test.stubs.dconf = { };

  test.asserts.assertions.expected = [''
    The attribute name of a Gnome Terminal profile must be a UUID.
    Incorrect profile names: another-bad-name, bad-name''];
}
