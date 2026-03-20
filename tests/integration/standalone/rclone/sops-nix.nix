{ pkgs, lib, ... }:
let
  commit = "3223c7a92724b5d804e9988c6b447a0d09017d48";
  agePub = "age1teupt3wxdyz454jmdf09c6387hafkg26tr8eqm9tawv53p29rfaqjq0dvu";
  ageKey = "AGE-SECRET-KEY-1XYQSNDSZ8E8GJRK2W5ATE5U58M6VQMC0Y0NVVA3RKQ9FUXEKTP9QR4Q3Z5";

  sops-nix = pkgs.fetchzip {
    url = "https://github.com/Mic92/sops-nix/archive/${commit}.tar.gz";
    hash = "sha256-t+voe2961vCgrzPFtZxha0/kmFSHFobzF00sT8p9h0U=";
  };

  secrets = pkgs.writeText "secrets.yaml" "password: aliceiscool2004";
  secretsEnc = pkgs.runCommand "secrets-enc.yaml" { } ''
    ${lib.getExe pkgs.sops} encrypt ${secrets} --age "${agePub}" > $out
  '';
in
{
  name = "rclone-sops-nix";

  nodes.machine = {
    imports = [ ../../../../nixos ];

    virtualisation.memorySize = 2048;
    users.users.alice = {
      isNormalUser = true;
      description = "Alice Foobar";
      password = "foobar";
      uid = 1000;
    };

    systemd.tmpfiles.rules = [
      "f /home/alice/age-key 400 alice users - ${ageKey}"
    ];

    home-manager.users.alice =
      { config, ... }:
      {
        imports = [ "${sops-nix}/modules/home-manager/sops.nix" ];

        home = {
          username = "alice";
          homeDirectory = "/home/alice";
          stateVersion = "24.05"; # Please read the comment before changing.
        };

        sops = {
          age.keyFile = "/home/alice/age-key";
          secrets.password.sopsFile = secretsEnc;
        };

        programs.rclone = {
          enable = true;
          remotes = {
            alices-encrypted-files = {
              config = {
                type = "crypt";
                remote = "/home/alice/enc-files";
              };

              secrets.password = config.sops.secrets.password.path;
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

    with subtest("Sops-nix activation ordering works correctly"):
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
