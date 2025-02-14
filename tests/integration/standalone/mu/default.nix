{ pkgs, ... }: {
  name = "mu-store-init";

  nodes.machine = { ... }: {
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

    home_manager = "${../../../..}"
    home_config = "/home/alice/.config/home-manager"

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

    def switch_to(config):
      succeed_as_alice(f"cp {home_config}/{config}.nix {home_config}/home.nix")
      return succeed_as_alice("home-manager switch")
      # succeed_as_alice(". /home/alice/.nix-profile/etc/profile.d/hm-session-vars.sh")

    # Create a persistent login so that Alice has a systemd session.
    login_as_alice()

    # Set up a home-manager channel.
    succeed_as_alice(" ; ".join([
      "mkdir -p /home/alice/.nix-defexpr/channels",
      f"ln -s {home_manager} /home/alice/.nix-defexpr/channels/home-manager"
    ]))

    succeed_as_alice("nix-shell \"<home-manager>\" -A install")

    succeed_as_alice(f"cp -t {home_config} ${./.}/config-*")

    with subtest("Switch to empty profile"):
      switch_to("config-no-accounts")
      actual = succeed_as_alice("mu info store")
      expected = "/home/alice/Maildir"
      assert expected in actual, \
        f"expected mu info store to contain {expected}, but got {actual}"
      unexpected = "personal-address"
      assert not unexpected in actual, \
        f"expected mu info store not to contain {unexpected}, but got {actual}"

    with subtest("Switch to profile with an account"):
      switch_to("config-one-account")
      actual = succeed_as_alice("mu info store")
      expected = "alice@example.com"
      assert expected in actual, \
        f"expected mu info store to contain {expected}, but got {actual}"

    with subtest("Switch to profile with two accounts"):
      switch_to("config-two-accounts")
      actual = succeed_as_alice("mu info store")
      expected = "alice@example.com"
      assert expected in actual, \
        f"expected mu info store to contain {expected}, but got {actual}"
      expected = "alice@example2.com"
      assert expected in actual, \
        f"expected mu info store to contain {expected}, but got {actual}"

    with subtest("Switch back to profile with one account"):
      switch_to("config-one-account")
      actual = succeed_as_alice("mu info store")
      expected = "alice@example.com"
      assert expected in actual, \
        f"expected mu info store to contain {expected}, but got {actual}"
      unexpected = "alice@example2.com"
      assert not unexpected in actual, \
        f"expected mu info store not to contain {unexpected}, but got {actual}"

    with subtest("Switch to profile with an alias"):
      switch_to("config-one-alias")
      actual = succeed_as_alice("mu info store")
      expected = "alice@example.com"
      assert expected in actual, \
        f"expected mu info store to contain {expected}, but got {actual}"
      expected = "alias@example.com"
      assert expected in actual, \
        f"expected mu info store to contain {expected}, but got {actual}"

    with subtest("Switch to a profile with mu disabled for one account"):
      switch_to("config-account-without-mu")
      actual = succeed_as_alice("mu info store")
      expected = "alice@example.com"
      assert expected in actual, \
        f"expected mu info store to contain {expected}, but got {actual}"
      unexpected = "alice@example2.com"
      assert not unexpected in actual, \
        f"expected mu info store not to contain {unexpected}, but got {actual}"
  '';
}
