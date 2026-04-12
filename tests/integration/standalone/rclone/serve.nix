{ pkgs, lib, ... }:
let
  sshKeys = import "${pkgs.path}/nixos/tests/ssh-keys.nix" pkgs;

  # https://rclone.org/sftp/#ssh-authentication
  keyPem = lib.pipe sshKeys.snakeOilEd25519PrivateKey.text [
    lib.trim
    (lib.replaceStrings [ "\n" ] [ "\\\\n" ])
  ];

  module = pkgs.writeText "serve-module" ''
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
          serve = {
            "/home/alice/files" = {
              enable = true;
              protocol = "http";
              options.addr = "localhost:8080";
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

    with subtest("Serve a remote over HTTP (sftp)"):
      # create files on remote
      succeed_as_alice(
        "mkdir /home/alice/files",
        "touch /home/alice/files/other_file"
        "echo serving > /home/alice/files/test.txt",
        box=remote
      )

      # fetch file from server
      output = succeed_as_alice(
        "curl -s http://localhost:8080/test.txt"
      )
      expected = "serving"
      assert expected in output, \
        f"HTTP server response does not contain expected content. Got: {output}"

      # verify file listing
      output = succeed_as_alice(
        "curl -s http://localhost:8080/"
      )
      assert "other_file" in output, \
        f"HTTP directory listing does not contain other_file. Got: {output}"
  '';
}
