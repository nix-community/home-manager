{
  systemd-services = ./services.nix;
  systemd-services-disabled-for-root = ./services-disabled-for-root.nix;
  systemd-session-variables = ./session-variables.nix;
  systemd-user-config = ./user-config.nix;
  systemd-default-user-config = ./default-user-config.nix;
  systemd-slices = ./slices.nix;
  systemd-timers = ./timers.nix;
  systemd-user-environment-generators = ./user-environment-generators.nix;
}
