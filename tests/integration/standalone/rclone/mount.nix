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
        "install -m644 ${module} /home/alice/.config/home-manager/test-remote.nix"
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
  '';
}
