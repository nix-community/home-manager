{ pkgs, ... }:
{
  name = "dconf";
  meta.maintainers = [ pkgs.lib.maintainers.rycee ];

  nodes.machine = {
    imports = [ "${pkgs.path}/nixos/modules/installer/cd-dvd/channel.nix" ];
    virtualisation.memorySize = 2048;
    users.users.alice = {
      isNormalUser = true;
      description = "Alice Foobar";
      password = "foobar";
      uid = 1000;
    };
    programs.dconf = {
      enable = true;
      profiles.custom = pkgs.writeText "dconf-profile-custom" ''
        user-db:custom
      '';
    };
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("network.target")
    machine.wait_for_unit("multi-user.target")

    home_manager = "${../../..}"

    def login_as_alice():
      machine.wait_until_tty_matches("1", "login: ")
      machine.send_chars("alice\n")
      machine.wait_until_tty_matches("1", "Password: ")
      machine.send_chars("foobar\n")
      machine.wait_until_tty_matches("1", "alice\\@machine")

    def logout_alice():
      machine.send_chars("exit\n")

    def alice_cmd(cmd):
      return f"su -l alice --shell /bin/sh -c $'export XDG_RUNTIME_DIR=/run/user/$UID ; {cmd}'"

    def succeed_as_alice(cmd):
      return machine.succeed(alice_cmd(cmd))

    def fail_as_alice(cmd):
      return machine.fail(alice_cmd(cmd))

    # Create a persistent login so that Alice has a systemd session.
    login_as_alice()

    # Set up a home-manager channel.
    succeed_as_alice(" ; ".join([
      "mkdir -p /home/alice/.nix-defexpr/channels",
      f"ln -s {home_manager} /home/alice/.nix-defexpr/channels/home-manager"
    ]))

    succeed_as_alice("nix-shell \"<home-manager>\" -A install")

    succeed_as_alice("cp ${./dconf-home.nix} /home/alice/.config/home-manager/home.nix")
    succeed_as_alice("home-manager switch")

    succeed_as_alice("test -e /home/alice/.config/dconf/user")
    actual = succeed_as_alice("dconf dump /")
    expected = """[foo]
    bar=42
    """
    assert actual == expected, "invalid content in dconf database \"user\""

    succeed_as_alice("test -e /home/alice/.config/dconf/custom")
    actual = succeed_as_alice("DCONF_PROFILE=custom dconf dump /")
    expected = """[foo1]
    bar1=42
    """
    assert actual == expected, "invalid content in dconf database \"custom\""
  '';
}
