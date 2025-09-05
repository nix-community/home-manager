{ pkgs, ... }:

{
  name = "standalone-specialisation";
  meta.maintainers = [ pkgs.lib.maintainers.rycee ];

  nodes.machine =
    { ... }:
    {
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
      # Install the configuration with included specialisation.
      succeed_as_alice("mkdir -p /home/alice/.config/home-manager")
      succeed_as_alice("cp ${./alice-home-specialisation.nix} /home/alice/.config/home-manager/home.nix")

      # Install Home Manager with the unspecialised configuration.
      succeed_as_alice("nix-shell \"<home-manager>\" -A install")

      # Ensure we are activated.
      machine.succeed("test -L /home/alice/.cache/.keep")

    with subtest("Home Manager switch to missing specialisation"):
      actual = fail_as_alice("home-manager switch --specialisation no-such-specialisation")
      expected = "The configuration did not contain the specialisation \"no-such-specialisation\""
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

    logout_alice()
  '';
}
