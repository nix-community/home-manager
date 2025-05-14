{ pkgs, ... }:

let
  sshKeys = import "${pkgs.path}/nixos/tests/ssh-keys.nix" pkgs;

  baseMachine = extend: {
    imports = [
      "${pkgs.path}/nixos/modules/installer/cd-dvd/channel.nix"
      extend
    ];
    virtualisation.memorySize = 2048;
    users.users.alice = {
      isNormalUser = true;
      description = "Alice Foobar";
      password = "foobar";
      uid = 1000;
    };
  };
in
{
  name = "rclone";

  nodes = {
    machine = baseMachine { };

    remote = baseMachine {
      services.openssh.enable = true;

      users.users.alice.openssh.authorizedKeys.keys = [
        sshKeys.snakeOilEd25519PublicKey
      ];
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

    def succeed_as_alice(*cmds, box=machine):
      return box.succeed(*map(alice_cmd,cmds))

    def systemctl_succeed_as_alice(cmd):
      status, out = machine.systemctl(cmd, "alice")
      assert status == 0, f"failed to run systemctl {cmd}"
      return out

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

    succeed_as_alice("cp ${./home.nix} /home/alice/.config/home-manager/home.nix")

    with subtest("Generate with no secrets"):
      succeed_as_alice("install -m644 ${./no-secrets.nix} /home/alice/.config/home-manager/test-remote.nix")

      actual = succeed_as_alice("home-manager switch")
      expected = "Activating createRcloneConfig"
      assert expected in actual, \
        f"expected home-manager switch to contain {expected}, but got {actual}"

      succeed_as_alice("diff -u ${./no-secrets.conf} /home/alice/.config/rclone/rclone.conf")

    with subtest("Generate with secrets from store"):
      succeed_as_alice("install -m644 ${./with-secrets-in-store.nix} /home/alice/.config/home-manager/test-remote.nix")

      actual = succeed_as_alice("home-manager switch")
      expected = "Activating createRcloneConfig"
      assert expected in actual, \
        f"expected home-manager switch to contain {expected}, but got {actual}"

      succeed_as_alice("diff -u ${./with-secrets-in-store.conf} /home/alice/.config/rclone/rclone.conf")

    with subtest("Secrets with spaces"):
      succeed_as_alice("install -m644 ${./secrets-with-whitespace.nix} /home/alice/.config/home-manager/test-remote.nix")

      actual = succeed_as_alice("home-manager switch")
      expected = "Activating createRcloneConfig"
      assert expected in actual, \
        f"expected home-manager switch to contain {expected}, but got {actual}"

      succeed_as_alice("diff -u ${./secrets-with-whitespace.conf} /home/alice/.config/rclone/rclone.conf")

    with subtest("Un-typed remote"):
      succeed_as_alice("install -m644 ${./no-type.nix} /home/alice/.config/home-manager/test-remote.nix")

      actual = fail_as_alice("home-manager switch")
      expected = "Activating createRcloneConfig"
      assert expected not in actual, \
        f"expected home-manager switch to contain {expected}, but got {actual}"

      expected = "An attribute set containing a remote type and options."
      assert expected not in actual, \
        f"expected home-manager switch to contain {expected}, but got {actual}"


    # TODO: verify correct activation order with the agenix and sops hm modules

    remote.wait_for_unit("network.target")
    remote.wait_for_unit("multi-user.target")

    with subtest("Mount a remote (sftp)"):
      # https://rclone.org/commands/rclone_mount/#vfs-directory-cache
      # Sending a SIGHUP evicts every dcache entry
      def clear_vfs_dcache():
        svc_name = "rclone-mount:.home.alice.files@alices-sftp-remote.service"
        succeed_as_alice(f"kill -s HUP $(systemctl --user show -p MainPID --value {svc_name})")
        succeed_as_alice(
          "sync",
          "sleep 5",
          box=remote
        )

      succeed_as_alice(
        "mkdir -p /home/alice/.ssh",
        "install -m644 ${./mount.nix} /home/alice/.config/home-manager/test-remote.nix"
      )

      actual = succeed_as_alice("home-manager switch")
      expected = "Activating createRcloneConfig"
      assert expected in actual, \
        f"expected home-manager switch to contain {expected}, but got {actual}"

      # remote -> machine
      succeed_as_alice(
        "mkdir /home/alice/files",
        "touch /home/alice/files/test",
        "echo started > /home/alice/files/log",
        box=remote
      )

      succeed_as_alice("ls /home/alice/remote-files/test")

      test_log = succeed_as_alice("cat /home/alice/remote-files/log")
      expected = "started";
      assert expected in test_log, \
        f"Mounted file does not have expected contents. Expected {test_log} to contain \"{expected}\""

      # machine -> remote
      succeed_as_alice(
        "touch /home/alice/remote-files/new-file",
        "echo testing this works both ways! >> /home/alice/remote-files/log",
      )

      clear_vfs_dcache()

      succeed_as_alice("ls /home/alice/files/new-file", box=remote)

      test_log = succeed_as_alice("cat /home/alice/files/log", box=remote)
      expected = "testing this works both ways!"
      assert expected in test_log, \
        f"Mounted file does not have expected contents. Expected {test_log} to contain \"{expected}\""

      expected = "started"
      assert expected in test_log, \
        f"Mounted file does not have expected contents. Expected {test_log} to contain \"{expected}\""

    logout_alice()
  '';
}
