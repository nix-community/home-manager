{
  espanso-basic-configuration = import ./basic-configuration.nix { };
  espanso-basic-configuration-wayland = import ./basic-configuration.nix {
    waylandSupport = true;
    x11Support = false;
  };
  espanso-basic-configuration-x11 = import ./basic-configuration.nix {
    waylandSupport = false;
    x11Support = true;
  };
}
