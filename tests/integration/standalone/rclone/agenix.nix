{ pkgs, lib, ... }:
let
  commit = "9edb1787864c4f59ae5074ad498b6272b3ec308d";
  sshKeys = import "${pkgs.path}/nixos/tests/ssh-keys.nix" pkgs;

  agenix = pkgs.fetchzip {
    url = "https://github.com/ryantm/agenix/archive/${commit}.tar.gz";
    hash = "sha256-NA/FT2hVhKDftbHSwVnoRTFhes62+7dxZbxj5Gxvghs=";
  };

  passwordFile = pkgs.writeText "password" "aliceiscool2004";
  passwordEnc = pkgs.runCommand "password-enc" { } ''
    ${lib.getExe pkgs.age} --encrypt \
      --recipient "${sshKeys.snakeOilEd25519PublicKey}" \
      --output $out \
       ${passwordFile}
  '';
in
{
  name = "rclone-agenix";

  nodes.machine = {
    imports = [ ../../../../nixos ];

    virtualisation.memorySize = 2048;
    users.users.alice = {
      isNormalUser = true;
      description = "Alice Foobar";
      password = "foobar";
      uid = 1000;
    };

    home-manager.users.alice =
      { config, ... }:
      {
        imports = [ "${agenix}/modules/age-home.nix" ];

        home = {
          username = "alice";
          homeDirectory = "/home/alice";
          stateVersion = "24.05"; # Please read the comment before changing.
        };

        age = {
          identityPaths = [ "${sshKeys.snakeOilEd25519PrivateKey}" ];
          secrets.password.file = "${passwordEnc}";
        };

        programs.rclone = {
          enable = true;
          remotes = {
            alices-encrypted-files = {
              config = {
                type = "crypt";
                remote = "/home/alice/enc-files";
              };

              secrets.password = config.age.secrets.password.path;
            };
          };
        };
      };
  };

  testScript = ''
    def alice_cmd(cmd):
      return f"su -l alice --shell /bin/sh -c $'export XDG_RUNTIME_DIR=/run/user/$UID ; {cmd}'"

    def succeed_as_alice(*cmds, box=machine):
      return box.succeed(*map(alice_cmd,cmds))

    def assert_list(cmd, expected_list, actual):
      assert all([x in actual for x in expected_list]), \
        f"""Expected {cmd} to contain \
            [{" and ".join([x for x in expected_list if x not in actual])}], but got {actual}"""

    start_all()
    machine.wait_for_unit("network.target")
    machine.wait_for_unit("multi-user.target")

    machine.wait_until_tty_matches("1", "login: ")
    machine.send_chars("alice\n")
    machine.wait_until_tty_matches("1", "Password: ")
    machine.send_chars("foobar\n")
    machine.wait_until_tty_matches("1", "alice\\@machine")

    with subtest("Agenix activation ordering works correctly"):
      # wait for rclone-config.service
      machine.wait_until_succeeds("grep password /home/alice/.config/rclone/rclone.conf")

      actual = succeed_as_alice("cat /home/alice/.config/rclone/rclone.conf")
      assert_list("/home/alice/.config/rclone/rclone.conf", [
        "[alices-encrypted-files]",
        "remote = /home/alice/enc-files",
        "type = crypt",
        "password = "
      ], actual)

      hidden_password = actual.strip().split("password = ")[1]
      password = succeed_as_alice(f"rclone reveal {hidden_password}")
      assert "aliceiscool2004" in password, \
        f"Failed to decrypt password. Instead of aliceiscool2004, we got {password}"
  '';
}
