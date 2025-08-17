{ pkgs, ... }:
let
  mkBrokenModule =
    passPath:
    pkgs.writeText "atomic-broken-module" ''
      {
        programs.rclone.remotes = {
          alices-broken-test-remote = {
            config = {
              type = "smb";
              host = "smb.alice.com";
              user = "alice";
              port = 1234;
            };
            secrets.pass = "${passPath}";
          };
        };
      }
    '';

  moduleNoSuchFileDir = mkBrokenModule "/this/path/does/not/exist";
  moduleSecretWithNewlines = mkBrokenModule (
    pkgs.writeText "newline-secret" "\ra\n secret\nwith\r\nnewlines"
  );

  workingRemote = pkgs.writeText "atomic-working-remote" ''
    [alices-working-remote]
    host=backup-server
    key_file=/key/path/foo
    type=sftp
    user=alice
  '';
in
{
  script = ''
    # Test we dont overwrite a working config with a broken/partial one, after and error occurs.
    with subtest("Writing the config is atomic through errors (no such file or directory)"):
      succeed_as_alice("install -m644 ${moduleNoSuchFileDir} /home/alice/.config/home-manager/test-remote.nix")
      succeed_as_alice("install -m644 -D ${workingRemote} /home/alice/.config/rclone/rclone.conf")

      actual = succeed_as_alice("home-manager switch")
      expected = "rclone-config.service"
      assert "Starting units: " in actual and expected in actual, \
        f"expected home-manager switch to contain {expected}, but got {actual}"

      succeed_as_alice("diff -u ${workingRemote} /home/alice/.config/rclone/rclone.conf")

      exit_status = machine.get_unit_property("rclone-config.service", "Result", "alice")
      assert "success" not in exit_status, "rclone-config.service unexpectedly ran successfully"

    with subtest("Writing the config is atomic through errors (secret with newlines)"):
      succeed_as_alice("install -m644 ${moduleSecretWithNewlines} /home/alice/.config/home-manager/test-remote.nix")

      actual = succeed_as_alice("home-manager switch")
      expected = "rclone-config.service"
      assert "Starting units: " in actual and expected in actual, \
        f"expected home-manager switch to contain {expected}, but got {actual}"

      succeed_as_alice("diff -u ${workingRemote} /home/alice/.config/rclone/rclone.conf")

      exit_status = machine.get_unit_property("rclone-config.service", "Result", "alice")
      assert "success" not in exit_status, "rclone-config.service unexpectedly ran successfully"
  '';
}
