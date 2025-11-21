{ pkgs, ... }:
let
  module = pkgs.writeText "write-after-module" ''
    {
      programs.rclone.writeAfter = "something";
    }
  '';
in
{
  script = ''
    with subtest("Use removed `writeAfter` option"):
      succeed_as_alice("install -m644 ${module} /home/alice/.config/home-manager/test-remote.nix")

      actual = fail_as_alice("home-manager switch 2>&1")
      expected = "rclone-config.service"
      assert expected not in actual, \
        f"expected home-manager switch to not contain {expected}, but got {actual}"

      snippet = "The writeAfter option has been removed because"
      assert snippet in actual, \
        f"expected home-manager switch to not contain {snippet}, but got {actual}"
  '';
}
