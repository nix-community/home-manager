{ ... }:
{
  imports = [ ../../../nixos ]; # Import the HM NixOS module.

  system.stateVersion = "24.11";

  users.users.alice = {
    isNormalUser = true;
  };

  home-manager = {
    users.alice =
      { ... }:
      {
        home.stateVersion = "24.11";
        home.file.test.text = "testfile new profile";
      };
  };
}
