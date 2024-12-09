{ pkgs, ... }: {
  name = "kitty-theme-path";
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

    succeed_as_alice("nix-shell \"<home-manager>\" -A install")

    with subtest("Switch to Bad Kitty"):
      succeed_as_alice("cp ${
        ./kitty-theme-bad-home.nix
      } /home/alice/.config/home-manager/home.nix")

      actual = fail_as_alice("home-manager switch")
      expected = "kitty-themes does not contain the theme file"
      assert expected in actual, \
        f"expected home-manager switch to contain {expected}, but got {actual}"

    with subtest("Switch to Good Kitty"):
      succeed_as_alice("cp ${
        ./kitty-theme-good-home.nix
      } /home/alice/.config/home-manager/home.nix")

      actual = succeed_as_alice("home-manager switch")
      expected = "Activating checkKittyTheme"
      assert expected in actual, \
        f"expected home-manager switch to contain {expected}, but got {actual}"
  '';
}
