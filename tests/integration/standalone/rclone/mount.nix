{ pkgs, lib, ... }:
let
  sshKeys = import "${pkgs.path}/nixos/tests/ssh-keys.nix" pkgs;

  # https://rclone.org/sftp/#ssh-authentication
  keyPem = lib.pipe sshKeys.snakeOilEd25519PrivateKey.text [
    lib.trim
    (lib.replaceStrings [ "\n" ] [ "\\\\n" ])
  ];

  module = pkgs.writeText "mount-module" ''
    { pkgs, lib, ... }: {
      programs.rclone.remotes = {
        alices-sftp-remote = {
          config = {
            type = "sftp";
            host = "remote";
            user = "alice";
            key_pem = "${keyPem}";
            known_hosts = "${sshKeys.snakeOilEd25519PublicKey}";
          };
          mounts = {
            "/home/alice/files" = {
              enable = true;
              mountPoint = "/home/alice/remote-files";
            };
          };
        };

        alices-disabled-remote = {
          config = {
            type = "sftp";
            host = "remote";
            user = "alice";
            key_pem = "${keyPem}";
            known_hosts = "${sshKeys.snakeOilEd25519PublicKey}";
          };
          mounts = {
            "/home/alice/other-files" = {
              mountPoint = "/home/alice/other-files";
            };
          };
        };

        non-automounted-remote = {
          config = {
            type = "sftp";
            host = "remote";
            user = "alice";
            key_pem = "${keyPem}";
            known_hosts = "${sshKeys.snakeOilEd25519PublicKey}";
          };
          mounts = {
            "/home/alice/even-more-files" = {
              enable = true;
              autoMount = false;
              mountPoint = "/home/alice/even-more-files";
            };
          };
        };
      };
    }
  '';
in
{
  nodes.remote = {
    services.openssh.enable = true;

    users.users.alice.openssh.authorizedKeys.keys = [
      sshKeys.snakeOilEd25519PublicKey
    ];
  };

  script = ''
    remote.wait_for_unit("network.target")
    remote.wait_for_unit("multi-user.target")

    succeed_as_alice(
      "mkdir -p /home/alice/.ssh",
      "install -m644 ${module} /home/alice/.config/home-manager/test-remote.nix"
    )

    actual = succeed_as_alice("home-manager switch")
    expected = "rclone-config.service"
    assert "Starting units: " in actual and expected in actual, \
      f"expected home-manager switch to contain {expected}, but got {actual}"

    with subtest("Disabled remotes aren't created"):
        svc_name = "rclone-mount:.home.alice.other-files@alices-disabled-remote.service"

        status, out = machine.systemctl(f"status {svc_name}", "alice")
        assert status != 0, \
          f"The disabled mount {svc_name} was created"

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

    with subtest("Non-automounted mounts aren't started"):
      svc_name = "rclone-mount:.home.alice.even-more-files@non-automounted-remote.service"

      _status, out = machine.systemctl(f"show -p WantedBy --value {svc_name}", "alice")
      assert not "default.target" in out, \
        f"Non-automounted service, {svc_name}, contains \"WantedBy\" default.target"

      fail_as_alice("ls /home/alice/even-more-files")

      succeed_as_alice(
        "mkdir /home/alice/even-more-files",
        box=remote
      )

      status, _out = machine.systemctl(f"start {svc_name}", "alice")
      assert status == 0, \
        f"Failed to start {svc_name}"

      succeed_as_alice("ls /home/alice/even-more-files")
  '';
}
