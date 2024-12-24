{ pkgs, ... }:

let

  inherit (pkgs.lib) escapeShellArg;

  nixHome = "/home/alice@home\\extra";
  pyHome = "/home/alice@home\\\\extra";

in {
  name = "home-with-symbols";
  meta.maintainers = [ pkgs.lib.maintainers.rycee ];

  nodes.machine = { ... }: {
    imports = [ "${pkgs.path}/nixos/modules/installer/cd-dvd/channel.nix" ];
    virtualisation.memorySize = 2048;
    users.users.alice = {
      isNormalUser = true;
      description = "Alice Foobar";
      password = "foobar";
      uid = 1000;
      home = nixHome;
    };
  };

  testScript = ''
    import shlex

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
      cmd = shlex.quote(f"export XDG_RUNTIME_DIR=/run/user/$UID ; {cmd}")
      print(f"CMD: {cmd}")
      return f"su -l alice --shell /bin/sh -c {cmd}"

    def succeed_as_alice(cmd):
      return machine.succeed(alice_cmd(cmd))

    def fail_as_alice(cmd):
      return machine.fail(alice_cmd(cmd))

    # Create a persistent login so that Alice has a systemd session.
    login_as_alice()

    # Set up a home-manager channel.
    succeed_as_alice(" ; ".join([
      "mkdir -p '${pyHome}/.nix-defexpr/channels'",
      f"ln -s {home_manager} '${pyHome}/.nix-defexpr/channels/home-manager'"
    ]))

    with subtest("Home Manager installation"):
      succeed_as_alice("nix-shell \"<home-manager>\" -A install")

      actual = machine.succeed("ls '${pyHome}/.config/home-manager'")
      assert actual == "home.nix\n", \
        f"unexpected content of ${pyHome}/.config/home-manager: {actual}"

      machine.succeed("diff -u ${
        ./home-with-symbols-init.nix
      } '${pyHome}/.config/home-manager/home.nix'")

      # The default configuration creates this link on activation.
      machine.succeed("test -L '${pyHome}/.cache/.keep'")
  '';
}
