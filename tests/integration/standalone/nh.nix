{ pkgs, ... }:

let

  inherit (pkgs.lib) escapeShellArg;

  home = "/home/alice";

in {
  name = "works-with-nh-stable";
  meta.maintainers = [ pkgs.lib.maintainers.rycee ];

  nodes.machine = { ... }: {
    imports = [ "${pkgs.path}/nixos/modules/installer/cd-dvd/channel.nix" ];
    virtualisation.memorySize = 2048;
    environment.systemPackages = [ pkgs.nh ];
    nix = {
      registry.home-manager.to = {
        type = "path";
        path = ../../..;
      };
      settings.extra-experimental-features = [ "nix-command" "flakes" ];
    };
    users.users.alice = {
      isNormalUser = true;
      description = "Alice Foobar";
      password = "foobar";
      uid = 1000;
      inherit home;
    };
  };

  testScript = ''
    import shlex

    start_all()
    machine.wait_for_unit("network.target")
    machine.wait_for_unit("multi-user.target")

    home_manager = "${../..}"

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
      return f"su -l alice --shell /bin/sh -c {cmd}"

    def succeed_as_alice(cmd):
      return machine.succeed(alice_cmd(cmd))

    def fail_as_alice(cmd):
      return machine.fail(alice_cmd(cmd))

    # Create a persistent login so that Alice has a systemd session.
    login_as_alice()

    # Set up a home-manager channel.
    succeed_as_alice(" ; ".join([
      "mkdir -p ${home}/.nix-defexpr/channels",
      f"ln -s {home_manager} ${home}/.nix-defexpr/channels/home-manager"
    ]))

    with subtest("Run nh home switch"):
      # Copy a configuration to activate.
      succeed_as_alice(" ; ".join([
        "mkdir -vp ${home}/.config/home-manager",
        "cp -v ${
          ./alice-flake-init.nix
        } ${home}/.config/home-manager/flake.nix",
        "cp -v ${./alice-home-next.nix} ${home}/.config/home-manager/home.nix"
      ]))

      actual = succeed_as_alice("nh home switch --no-nom '${home}/.config/home-manager'")
      expected = "Starting Home Manager activation"
      assert expected in actual, \
        f"expected nh home switch to contain {expected}, but got {actual}"

      # The default configuration creates this link on activation.
      machine.succeed("test -L '${home}/.cache/.keep'")
  '';
}
