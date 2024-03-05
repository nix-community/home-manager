{ pkgs, ... }:

{
  name = "nixos-basics";
  meta.maintainers = [ pkgs.lib.maintainers.rycee ];

  nodes.machine = { ... }: {
    imports = [ ../../../nixos ]; # Import the HM NixOS module.

    users.users.alice = { isNormalUser = true; };

    home-manager.users.alice = { ... }: {
      home.stateVersion = "23.11";
      home.file.test.text = "testfile";
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

    with subtest("GC root and profile"):
      # There should be a GC root and Home Manager profile and they should point
      # to the same path in the Nix store.
      gcroot = "/home/alice/.local/state/home-manager/gcroots/current-home"
      gcrootTarget = machine.succeed(f"readlink {gcroot}")

      profile = "/home/alice/.local/state/nix/profiles"
      profileTarget = machine.succeed(f"readlink {profile}/home-manager")
      profile1Target = machine.succeed(f"readlink {profile}/{profileTarget}")

      assert gcrootTarget == profile1Target, \
        f"expected GC root and profile to point to same, but pointed to {gcrootTarget} and {profile1Target}"
  '';
}
