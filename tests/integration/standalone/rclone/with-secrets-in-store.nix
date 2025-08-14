{ pkgs, ... }:
let
  module = pkgs.writeText "with-secrets-in-store-module" ''
    {
      programs.rclone.remotes = {
        alices-cool-remote-v2 = {
          config = {
            type = "b2";
            hard_delete = true;
          };
          secrets = {
            account = "${pkgs.writeText "acc" "super-secret-account-id"}";
            key = "${pkgs.writeText "key" "api-key-from-file"}";
          };
        };
      };
    }
  '';

  expected = pkgs.writeText "with-secrets-in-store-expected" ''
    [alices-cool-remote-v2]
    hard_delete = true
    type = b2
    account = super-secret-account-id
    key = api-key-from-file

  '';
in
{
  script = ''
    with subtest("Generate with secrets from store"):
      succeed_as_alice("install -m644 ${module} /home/alice/.config/home-manager/test-remote.nix")

      actual = succeed_as_alice("home-manager switch")
      expected = "Activating createRcloneConfig"
      assert expected in actual, \
        f"expected home-manager switch to contain {expected}, but got {actual}"

      succeed_as_alice("diff -u ${expected} /home/alice/.config/rclone/rclone.conf")
  '';
}
