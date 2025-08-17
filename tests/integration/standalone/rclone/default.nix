{
  pkgs,
  lib,
  config,
  ...
}:

let
  baseMachine = {
    imports = [ "${pkgs.path}/nixos/modules/installer/cd-dvd/channel.nix" ];
    virtualisation.memorySize = 2048;
    users.users.alice = {
      isNormalUser = true;
      description = "Alice Foobar";
      password = "foobar";
      uid = 1000;
    };
  };
in
{
  imports = [
    ./no-secrets.nix
    ./with-secrets-in-store.nix
    ./secrets-with-whitespace.nix
    ./no-type.nix
    ./mount.nix
    ./shell.nix
    ./atomic.nix
    ./write-after.nix
  ];

  options.script = lib.mkOption {
    type = lib.types.lines;
  };

  config = {
    name = "rclone";

    nodes = {
      machine = baseMachine;
      remote = baseMachine;
    };

    testScript = ''
      start_all()
      machine.wait_for_unit("network.target")
      machine.wait_for_unit("multi-user.target")

      home_manager = "${../../../..}"

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

      def succeed_as_alice(*cmds, box=machine):
        return box.succeed(*map(alice_cmd,cmds))

      def systemctl_succeed_as_alice(cmd):
        status, out = machine.systemctl(cmd, "alice")
        assert status == 0, f"failed to run systemctl {cmd}"
        return out

      def fail_as_alice(*cmds):
        return machine.fail(*map(alice_cmd,cmds))

      # Create a persistent login so that Alice has a systemd session.
      login_as_alice()

      # Set up a home-manager channel.
      succeed_as_alice(" ; ".join([
        "mkdir -p /home/alice/.nix-defexpr/channels",
        f"ln -s {home_manager} /home/alice/.nix-defexpr/channels/home-manager"
      ]))

      with subtest("Home Manager installation"):
        succeed_as_alice("nix-shell \"<home-manager>\" -A install")

      succeed_as_alice("cp ${./home.nix} /home/alice/.config/home-manager/home.nix")

      ${config.script}

      logout_alice()
    '';
  };
}
