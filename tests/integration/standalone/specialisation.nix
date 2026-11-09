{ pkgs, ... }:

{
  name = "standalone-specialisation";
  meta.maintainers = [ pkgs.lib.maintainers.rycee ];

  nodes.machine = {
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

    with subtest("Home Manager files-only activation on a new account"):
      # Build the configuration without installing it, so that the account
      # has no Nix profile directory and no Home Manager state yet.
      succeed_as_alice(
        "nix-build \"<home-manager/home-manager/home-manager.nix>\""
        " --argstr confPath ${./alice-home-specialisation.nix}"
        " -A activationPackage -o /home/alice/prebuilt"
      )
      profiles = "/home/alice/.local/state/nix/profiles /nix/var/nix/profiles/per-user/alice"
      machine.succeed(f"for p in {profiles}; do test ! -e $p; done")

      # The files are placed with no profile, and the generation is not
      # recorded; the installation below completes the activation.
      succeed_as_alice("/home/alice/prebuilt/activate --driver-version 1 --files-only")
      machine.succeed("grep -qx test /home/alice/test")
      machine.succeed(f"for p in {profiles}; do test ! -e $p; done")
      machine.succeed("test ! -e /home/alice/.local/state/home-manager/gcroots/current-home")
      machine.succeed("rm /home/alice/prebuilt")

    with subtest("Home Manager installation"):
      # Install the configuration with included specialisation.
      succeed_as_alice("mkdir -p /home/alice/.config/home-manager")
      succeed_as_alice("cp ${./alice-home-specialisation.nix} /home/alice/.config/home-manager/home.nix")

      # Install Home Manager with the unspecialised configuration.
      succeed_as_alice("nix-shell \"<home-manager>\" -A install")

      # Ensure we are activated. The files-only run above placed the files
      # already, but only a full activation records the generation.
      machine.succeed("test -L /home/alice/.cache/.keep")
      machine.succeed("test -e /home/alice/.local/state/home-manager/gcroots/current-home")

    with subtest("Home Manager switch to missing specialisation"):
      actual = fail_as_alice("home-manager switch --specialisation no-such-specialisation")
      expected = "The configuration does not contain the specialisation \"no-such-specialisation\""
      assert expected in actual, \
        f"expected home-manager switch to contain {expected}, but got {actual}"

    with subtest("Home Manager switch to specialisation"):
      actual = succeed_as_alice("home-manager switch --specialisation pueue")
      expected = "Starting units: pueued.service"
      assert expected in actual, \
        f"expected home-manager switch to contain {expected}, but got {actual}"

      actual = succeed_as_alice("pueue status")
      expected = "running"
      assert expected in actual, \
        f"expected pueue status to contain {expected}, but got {actual}"

    with subtest("Home Manager switch back to base configuration"):
      actual = succeed_as_alice("home-manager switch")
      expected = "Stopping units: pueued.service"
      assert expected in actual, \
        f"expected home-manager switch to contain {expected}, but got {actual}"

      fail_as_alice("pueue status")

    with subtest("Home Manager files-only activation of specialisation"):
      gcroot = "/home/alice/.local/state/home-manager/gcroots/current-home"
      generation = machine.succeed(f"readlink -e {gcroot}").strip()
      activate = f"{generation}/specialisation/pueue/activate --driver-version 1"
      machine.succeed("rm -f /home/alice/test-changes")
      machine.succeed("test -L /home/alice/base-only")

      # Only the file blocks run: the files are placed and the hook runs.
      # The run succeeds although the hook ends in a failed condition.
      actual = succeed_as_alice(f"{activate} --files-only")
      blocks = sorted(
        line.removeprefix("Activating ")
        for line in actual.splitlines()
        if line.startswith("Activating ")
      )
      expected = [
        "checkFilesChanged", "checkLinkTargets", "linkGeneration", "onFilesChange"
      ]
      assert blocks == expected, \
        f"expected the files-only run to activate {expected}, but got {blocks}"
      machine.succeed("grep -qx pueue /home/alice/test")
      machine.succeed("test ! -e /home/alice/base-only")
      actual = machine.succeed("cat /home/alice/test-changes")
      assert actual == "changed\n", f"expected the hook to run once, but got {actual}"

      # The service is not started and the generation is not recorded.
      fail_as_alice("systemctl --user is-active pueued.service")
      actual = machine.succeed(f"readlink -e {gcroot}").strip()
      assert actual == generation, \
        f"expected {gcroot} to stay {generation}, but got {actual}"

      # The full activation completes the switch without running the hook again.
      actual = succeed_as_alice(activate)
      expected = "Starting units: pueued.service"
      assert expected in actual, \
        f"expected the activation to contain {expected}, but got {actual}"
      unexpected = "does not link into a Home Manager generation"
      assert unexpected not in actual, \
        f"expected the activation not to contain {unexpected}, but got {actual}"
      actual = machine.succeed("cat /home/alice/test-changes")
      assert actual == "changed\n", f"expected the hook to run once, but got {actual}"

    logout_alice()
  '';
}
