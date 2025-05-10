{ pkgs, ... }:

{
  name = "nixos-legacy-profile-management";
  meta.maintainers = [ pkgs.lib.maintainers.rycee ];

  nodes.machine =
    { ... }:
    {
      imports = [
        # Make the nixpkgs channel available.
        "${pkgs.path}/nixos/modules/installer/cd-dvd/channel.nix"
        # Import the HM NixOS module.
        ../../../nixos
      ];

      system.stateVersion = "24.11";

      users.users.alice = {
        isNormalUser = true;
      };

      specialisation = {
        legacy.configuration = {
          home-manager = {
            # Force legacy profile management.
            enableLegacyProfileManagement = true;

            users.alice =
              { ... }:
              {
                home.stateVersion = "24.11";
                home.file.test.text = "testfile legacy";
              };
          };
        };

        modern.configuration = {
          home-manager = {
            # Assert that we expect the option to default to false.
            enableLegacyProfileManagement = pkgs.lib.mkOptionDefault false;

            users.alice =
              { ... }:
              {
                home.stateVersion = "24.11";
                home.file.test.text = "testfile modern";
              };
          };
        };
      };
    };

  testScript =
    { nodes, ... }:
    let
      legacy = "${nodes.machine.system.build.toplevel}/specialisation/legacy";
      modern = "${nodes.machine.system.build.toplevel}/specialisation/modern";
    in
    ''
      start_all()

      machine.wait_for_unit("multi-user.target")

      machine.succeed("${legacy}/bin/switch-to-configuration test >&2")
      machine.wait_for_console_text("Finished Home Manager environment for alice.")

      with subtest("Home Manager file"):
        # The file should be linked with the expected content.
        path = "/home/alice/test"
        machine.succeed(f"test -L {path}")
        actual = machine.succeed(f"cat {path}")
        expected = "testfile legacy"
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

      with subtest("Switch to new profile management"):
        machine.succeed("${modern}/bin/switch-to-configuration test >&2")
        machine.wait_for_console_text("Finished Home Manager environment for alice.")

        # The file should be linked with the expected content.
        path = "/home/alice/test"
        machine.succeed(f"test -L {path}")
        actual = machine.succeed(f"cat {path}")
        expected = "testfile modern"
        assert actual == expected, f"expected {path} to contain {expected}, but got {actual}"

      with subtest("Switch back to old profile management"):
        machine.succeed("${legacy}/bin/switch-to-configuration test >&2")
        machine.wait_for_console_text("Finished Home Manager environment for alice.")

        # The file should be linked with the expected content.
        path = "/home/alice/test"
        machine.succeed(f"test -L {path}")
        actual = machine.succeed(f"cat {path}")
        expected = "testfile legacy"
        assert actual == expected, f"expected {path} to contain {expected}, but got {actual}"
    '';
}
