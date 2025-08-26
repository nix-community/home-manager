{ pkgs, ... }:
let
  module = pkgs.writeText "no-type-module" ''
    {
      programs.rclone.remotes = {
        alices-cool-remote-v4.config = {
          description = "this value does not have a type";
          some-key = "value pairs";
          another-key-value = "pair";
        };
      };
    }
  '';
in
{
  script = ''
    with subtest("Un-typed remote"):
      succeed_as_alice("install -m644 ${module} /home/alice/.config/home-manager/test-remote.nix")

      actual = fail_as_alice("home-manager switch")
      expected = "rclone-config.service"
      assert expected not in actual, \
        f"expected home-manager switch to not contain {expected}, but got {actual}"

      expected = "An attribute set containing a remote type and options."
      assert expected not in actual, \
        f"expected home-manager switch to contain {expected}, but got {actual}"
  '';
}
