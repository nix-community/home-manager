{ pkgs, ... }:
let
  module = pkgs.writeText "no-secrets-module" ''
    {
      programs.rclone.remotes = {
        alices-cool-remote.config = {
          type = "sftp";
          host = "backup-server";
          user = "alice";
          key_file = "/key/path/foo";
        };
      };
    }
  '';

  expected = pkgs.writeText "no-secrets-expected" ''
    [alices-cool-remote]
    host=backup-server
    key_file=/key/path/foo
    type=sftp
    user=alice
  '';
in
{
  script = ''
    with subtest("Generate with no secrets"):
      succeed_as_alice("install -m644 ${module} /home/alice/.config/home-manager/test-remote.nix")

      actual = succeed_as_alice("home-manager switch")
      expected = "rclone-config.service"
      assert "Starting units: " in actual and expected in actual, \
        f"expected home-manager switch to contain {expected}, but got {actual}"

      succeed_as_alice("diff -u ${expected} /home/alice/.config/rclone/rclone.conf")
  '';
}
