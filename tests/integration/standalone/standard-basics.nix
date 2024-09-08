{ pkgs, ... }:

{
  name = "standalone-standard-basics";
  meta.maintainers = [ pkgs.lib.maintainers.rycee ];

  nodes.machine = { ... }: {
    imports = [ "${pkgs.path}/nixos/modules/installer/cd-dvd/channel.nix" ];
    virtualisation.memorySize = 2048;
    users.users.alice = {
      isNormalUser = true;
      description = "Alice Foobar";
      password = "foobar";
      uid = 1000;
    };
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("network.target")
    machine.wait_for_unit("multi-user.target")

    home_manager = "${../../..}"

    def login_as_alice():
      machine.wait_until_tty_matches("1", "login: ")
      machine.send_chars("alice\n")
      machine.wait_until_tty_matches("1", "Password: ")
      machine.send_chars("foobar\n")
      machine.wait_until_tty_matches("1", "alice\\@machine")

    def logout_alice():
      machine.send_chars("exit\n")

    def alice_cmd(cmd):
      return f"su -l alice --shell /bin/sh -c $'export XDG_RUNTIME_DIR=/run/user/$UID ; {cmd}'"

    def succeed_as_alice(cmd):
      return machine.succeed(alice_cmd(cmd))

    def fail_as_alice(cmd):
      return machine.fail(alice_cmd(cmd))

    # Create a persistent login so that Alice has a systemd session.
    login_as_alice()

    # Set up a home-manager channel.
    succeed_as_alice(" ; ".join([
      "mkdir -p /home/alice/.nix-defexpr/channels",
      f"ln -s {home_manager} /home/alice/.nix-defexpr/channels/home-manager"
    ]))

    with subtest("Home Manager installation"):
      succeed_as_alice("nix-shell \"<home-manager>\" -A install")

      actual = machine.succeed("ls /home/alice/.config/home-manager")
      assert actual == "home.nix\n", \
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
      fail_as_alice("hello")

      succeed_as_alice("cp ${
        ./alice-home-next.nix
      } /home/alice/.config/home-manager/home.nix")

      actual = succeed_as_alice("home-manager switch")
      expected = "Starting units: pueued.service"
      assert expected in actual, \
        f"expected home-manager switch to contain {expected}, but got {actual}"

      succeed_as_alice("hello")

      actual = succeed_as_alice("echo $EDITOR").strip()
      assert "emacs" == actual, \
        f"expected $EDITOR to contain emacs, but found {actual}"

      actual = machine.succeed("systemctl --user -M alice@.host status pueued.service")
      expected = "running"
      assert expected in actual, \
        f"expected systemctl status pueued status to contain {expected}, but got {actual}"

      actual = succeed_as_alice("pueue status")
      expected = "running"
      assert expected in actual, \
        f"expected pueue status to contain {expected}, but got {actual}"

    with subtest("Home Manager generations"):
      actual = succeed_as_alice("home-manager generations")
      expected = ": id 1 ->"
      assert expected in actual, \
        f"expected generations to contain {expected}, but found {actual}"

    with subtest("Home Manager uninstallation"):
      succeed_as_alice("yes | home-manager uninstall -L")

      fail_as_alice("hello")
      machine.succeed("test ! -e /home/alice/.cache/.keep")

      # TODO: Fix uninstall to fully remove the share directory.
      machine.succeed("test ! -e /home/alice/.local/share/home-manager/gcroots")
      machine.succeed("test ! -e /home/alice/.local/state/home-manager")
      machine.succeed("test ! -e /home/alice/.local/state/nix/profiles/home-manager")

    logout_alice()
  '';
}
