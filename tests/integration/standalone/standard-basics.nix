{ pkgs, ... }:

{
  name = "standalone-standard-basics";
  meta.maintainers = [ pkgs.lib.maintainers.rycee ];

  nodes.machine = { ... }: {
    imports = [ "${pkgs.path}/nixos/modules/installer/cd-dvd/channel.nix" ];
    virtualisation.memorySize = 2048;
    users.users.alice = { isNormalUser = true; };
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("network.target")
    machine.wait_for_unit("multi-user.target")

    home_manager = "${../../..}"

    def as_alice(cmd):
      return machine.succeed(f"su - alice -c '{cmd}'")

    # Set up a home-manager channel.
    as_alice("mkdir -p /home/alice/.nix-defexpr/channels")
    as_alice(f"ln -s {home_manager} /home/alice/.nix-defexpr/channels/home-manager")

    with subtest("Home Manager installation"):
      as_alice("nix-shell \"<home-manager>\" -A install")

      actual = machine.succeed("ls /home/alice/.config/home-manager")
      expected = "home.nix\n"
      assert actual == expected, \
        f"unexpected content of /home/alice/.config/home-manager: {actual}"

      machine.succeed("diff -u ${
        ./alice-home-init.nix
      } /home/alice/.config/home-manager/home.nix")

      # The default configuration creates this link on activation.
      machine.succeed("test -L /home/alice/.cache/.keep")

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

    with subtest("Home Manager switch"):
      as_alice("cp ${
        ./alice-home-next.nix
      } /home/alice/.config/home-manager/home.nix")

      as_alice("home-manager switch")
      as_alice("hello")

      actual = as_alice("echo -n $EDITOR")
      assert "emacs" == actual, \
        f"expected $EDITOR to contain emacs, but found {actual}"

    with subtest("Home Manager generations"):
      actual = as_alice("home-manager generations")
      expected = ": id 1 ->"
      assert expected in actual, \
        f"expected generations to contain {expected}, but found {actual}"

    with subtest("Home Manager uninstallation"):
      as_alice("yes | home-manager uninstall -L")

      as_alice("! hello")
      machine.succeed("test ! -e /home/alice/.cache/.keep")

      # TODO: Fix uninstall to fully remove the directory.
      machine.succeed("test ! -e /home/alice/.local/share/home-manager/gcroots")
      machine.succeed("test ! -e /home/alice/.local/state/home-manager")
      machine.succeed("test ! -e /home/alice/.local/state/nix/profiles/home-manager")
  '';
}
