{ pkgs, ... }:

{
  name = "nixos-basics";
  meta.maintainers = [ pkgs.lib.maintainers.rycee ];

  nodes.machine = { ... }: {
    imports = [ ../../../nixos ]; # Import the HM NixOS module.

    system.stateVersion = "23.11";

    users.users.alice = { isNormalUser = true; };

    home-manager = {
      enableLegacyProfileManagement = false;

      users.alice = { ... }: {
        home.stateVersion = "23.11";
        home.file.test.text = "testfile";
      };
    };
  };

  testScript = ''
    start_all()

    machine.wait_for_unit("home-manager-alice.service")

    with subtest("Home Manager file"):
      # The file should be linked with the expected content.
      path = "/home/alice/test"
      machine.succeed(f"test -L {path}")
      actual = machine.succeed(f"cat {path}")
      expected = "testfile"
      assert actual == expected, f"expected {path} to contain {expected}, but got {actual}"

    with subtest("no GC root and profile"):
      # There should be no GC root and Home Manager profile since we are not
      # using legacy profile management.
      hmState = "/home/alice/.local/state/home-manager"
      machine.succeed(f"test ! -e {hmState}")

      hmProfile = "/home/alice/.local/state/nix/profiles/home-manager"
      machine.succeed(f"test ! -e {hmProfile}")
  '';
}
