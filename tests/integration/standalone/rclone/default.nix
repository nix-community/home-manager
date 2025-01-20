{ pkgs, ... }:

{
  name = "rclone";

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

    home_manager = "${../../../..}"

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

    def succeed_as_alice(*cmds):
      return machine.succeed(*map(alice_cmd,cmds))

    def fail_as_alice(*cmds):
      return machine.fail(*map(alice_cmd,cmds))

    # Create a persistent login so that Alice has a systemd session.
    login_as_alice()

    # Set up a home-manager channel.
    succeed_as_alice(" ; ".join([
      "mkdir -p /home/alice/.nix-defexpr/channels",
      f"ln -s {home_manager} /home/alice/.nix-defexpr/channels/home-manager"
    ]))

    with subtest("Home Manager installation"):
      succeed_as_alice("nix-shell \"<home-manager>\" -A install")

    succeed_as_alice("cp ${
      ./home.nix
    } /home/alice/.config/home-manager/home.nix")

    with subtest("Generate with no secrets"):
      succeed_as_alice("install -m644 ${
        ./no-secrets.nix
      } /home/alice/.config/home-manager/test-remote.nix")

      actual = succeed_as_alice("home-manager switch")
      expected = "Activating createRcloneConfig"
      assert expected in actual, \
        f"expected home-manager switch to contain {expected}, but got {actual}"

      succeed_as_alice("diff -u ${
        ./no-secrets.conf
      } /home/alice/.config/rclone/rclone.conf")

    with subtest("Generate with secrets from store"):
      succeed_as_alice("install -m644 ${
        ./with-secrets-in-store.nix
      } /home/alice/.config/home-manager/test-remote.nix")

      actual = succeed_as_alice("home-manager switch")
      expected = "Activating createRcloneConfig"
      assert expected in actual, \
        f"expected home-manager switch to contain {expected}, but got {actual}"

      succeed_as_alice("diff -u ${
        ./with-secrets-in-store.conf
      } /home/alice/.config/rclone/rclone.conf")

    # TODO: verify correct activation order with the agenix and sops hm modules

    logout_alice()
  '';
}
