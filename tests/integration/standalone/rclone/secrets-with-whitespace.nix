{ pkgs, ... }:
let
  module = pkgs.writeText "secrets-with-whitespace-module" ''
    {
      programs.rclone.remotes = {
        alices-cool-remote-v3 = {
          config = {
            type = "memory";
            description = "alices speeedy remote";
          };
          secrets.spaces-secret = "${pkgs.writeText "secret" ''
            This is a secret with spaces, it has single spaces,        and lots of spaces :3
          ''}";
        };
      };
    }
  '';

  expected = pkgs.writeText "secrets-with-whitespace-expected" ''
    [alices-cool-remote-v3]
    description = alices speeedy remote
    type = memory
    spaces-secret = This is a secret with spaces, it has single spaces,        and lots of spaces :3

  '';
in
{
  script = ''
    with subtest("Secrets with spaces"):
      succeed_as_alice("install -m644 ${module} /home/alice/.config/home-manager/test-remote.nix")

      actual = succeed_as_alice("home-manager switch")
      expected = "rclone-config.service"
      assert "Starting units: " in actual and expected in actual, \
        f"expected home-manager switch to contain {expected}, but got {actual}"

      succeed_as_alice("diff -u ${expected} /home/alice/.config/rclone/rclone.conf")
  '';
}
