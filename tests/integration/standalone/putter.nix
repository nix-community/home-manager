{ pkgs, ... }:

{
  name = "standalone-putter";
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

    with subtest("Home Manager installation"):
      succeed_as_alice("nix-shell \"<home-manager>\" -A install")

      actual = machine.succeed("ls /home/alice/.config/home-manager")
      assert actual == "home.nix\n", \
        f"unexpected content of /home/alice/.config/home-manager: {actual}"

      machine.succeed("diff -u ${./alice-home-init.nix} /home/alice/.config/home-manager/home.nix")

      # The default configuration creates this link on activation.
      machine.succeed("test -L /home/alice/.cache/.keep")

    with subtest("Activate with Putter"):
      succeed_as_alice("cp ${
        pkgs.substitute {
          src = ./alice-home-file-activator.nix;
          substitutions = [
            "--replace"
            "@fileActivator@"
            "putter"
          ];
        }
      } /home/alice/.config/home-manager/home.nix")

      succeed_as_alice("home-manager switch")

      machine.succeed("test -L /home/alice/test")

    with subtest("Home Manager uninstallation"):
      succeed_as_alice("yes | home-manager uninstall -L")

      machine.succeed("test ! -e /home/alice/.cache/.keep")
      machine.succeed("test ! -e /home/alice/.cache/test")

      # TODO: Fix uninstall to fully remove the share directory.
      machine.succeed("test ! -e /home/alice/.local/share/home-manager/gcroots")
      machine.succeed("test ! -e /home/alice/.local/state/home-manager")
      machine.succeed("test ! -e /home/alice/.local/state/nix/profiles/home-manager")

    logout_alice()
  '';
}
