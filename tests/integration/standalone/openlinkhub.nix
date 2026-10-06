{ lib, pkgs, ... }:

{
  name = "openlinkhub";
  meta.maintainers = with lib.maintainers; [ mikaeladev ];

  nodes.machine = {
    imports = [ "${pkgs.path}/nixos/modules/installer/cd-dvd/channel.nix" ];
    virtualisation.memorySize = 2048;
    users.users.alice = {
      isNormalUser = true;
      description = "Alice Foobar";
      password = "foobar";
      uid = 1000;
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

    login_as_alice()

    succeed_as_alice(" ; ".join([
      "mkdir -p /home/alice/.nix-defexpr/channels",
      f"ln -s {home_manager} /home/alice/.nix-defexpr/channels/home-manager"
    ]))

    succeed_as_alice("nix-shell \"<home-manager>\" -A install")

    succeed_as_alice("cp ${./openlinkhub-home.nix} /home/alice/.config/home-manager/home.nix")
    succeed_as_alice("home-manager switch")

    succeed_as_alice("test -d /home/alice/.config/OpenLinkHub/database")

    machine.wait_for_unit("systemd-tmpfiles-setup.service", "alice")

    succeed_as_alice("test -d /run/user/1000/OpenLinkHub")
    succeed_as_alice("test /run/user/1000/OpenLinkHub/database -ef /home/alice/.config/OpenLinkHub/database")

    machine.wait_for_unit("OpenLinkHub.service", "alice")
    machine.wait_for_open_port(27003)

    logout_alice()
  '';
}
