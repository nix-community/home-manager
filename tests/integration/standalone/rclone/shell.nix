{ pkgs, config, ... }:
let
  mkHttpModule =
    httpHeadersPath:
    pkgs.writeText "shell-module" ''
      {
        programs.rclone.remotes = {
          alices-remote-with-shell-vars = {
            config = {
              type = "http";
              url = "files.alice.com";
            };
            secrets.http-headers = "${httpHeadersPath}";
          };
        };
      }
    '';

  expected = pkgs.writeText "shell-expected" ''
    [alices-remote-with-shell-vars]
    type = http
    url = files.alice.com
    http-headers = Cookie,secret_password=aliceiscool

  '';

  xdgRuntimeDir = "/run/user/${builtins.toString config.nodes.machine.users.users.alice.uid}";
  httpHeadersSecret = pkgs.writeText "http-headers" "Cookie,secret_password=aliceiscool";

  shellVar = mkHttpModule "\\\${XDG_RUNTIME_DIR}/http-headers";
  shellCmd = mkHttpModule "$(printf '${xdgRuntimeDir}')/http-headers";
in
{
  script = ''
    succeed_as_alice("install -m644 ${httpHeadersSecret} ${xdgRuntimeDir}/http-headers")

    def test_bash_expansion(module):
      succeed_as_alice(f"install -m644 {module} /home/alice/.config/home-manager/test-remote.nix")

      actual = succeed_as_alice("home-manager switch")
      expected = "rclone-config.service"
      assert "Starting units: " in actual and expected in actual, \
        f"expected home-manager switch to contain {expected}, but got {actual}"

      succeed_as_alice("diff -u ${expected} /home/alice/.config/rclone/rclone.conf")

    with subtest("Generate with shell variable in secrets"):
      test_bash_expansion("${shellVar}")

    # cleanup
    succeed_as_alice("rm /home/alice/.config/rclone/rclone.conf")
    succeed_as_alice("rm /home/alice/.config/home-manager/test-remote.nix")

    with subtest("Generate with shell cmd in secrets"):
      test_bash_expansion("${shellCmd}")
  '';
}
