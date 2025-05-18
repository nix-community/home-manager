{ pkgs, lib, ... }:
let
  testDir = pkgs.runCommand "test-files-to-backup" { } ''
    mkdir $out
    echo some_file > $out/some_file
    echo some_other_file > $out/some_other_file
    mkdir $out/a_dir
    echo a_file > $out/a_dir/a_file
    echo a_file_2 > $out/a_dir/a_file_2
    echo alices-secret-diary > $out/a_dir/excluded_file_1
    echo alices-bank-details > $out/excluded_file_2
  '';

  dynDir = testDir.overrideAttrs (
    final: prev: {
      buildCommand =
        prev.buildCommand
        + ''
          echo more secret data > $out/top-secret
          echo shhhh > $out/top-secret-v2
          echo this isnt secret > $out/metadata
        '';
    }
  );
in
{
  name = "restic";

  nodes.machine =
    { ... }:
    {
      imports = [ "${pkgs.path}/nixos/modules/installer/cd-dvd/channel.nix" ];
      virtualisation.memorySize = 2048;
      users.users.alice = {
        isNormalUser = true;
        description = "Alice Foobar";
        password = "foobar";
        uid = 1000;
      };

      security.polkit.enable = true;
    };

  testScript = ''
    start_all()
    machine.wait_for_unit("network.target")
    machine.wait_for_unit("multi-user.target")
    machine.wait_for_unit("dbus.socket")

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

    def succeed_as_alice(*cmds):
      return machine.succeed(*map(alice_cmd,cmds))

    def fail_as_alice(*cmds):
      return machine.fail(*map(alice_cmd,cmds))

    def systemctl_succeed_as_alice(cmd):
      status, out = machine.systemctl(cmd, "alice")
      assert status == 0, f"failed to run systemctl {cmd}"
      return out

    def systemctl_fail_as_alice(cmd):
      status, out = machine.systemctl(cmd, "alice")
      assert status != 0, \
        f"Successfully finished with exit-code {status}, systemctl {cmd} when its expected to fail"
      return out

    def assert_list(cmd, expected_list, actual):
      assert all([x in actual for x in expected_list]), \
        f"""Expected {cmd} to contain \
            [{" and ".join([x for x in expected_list if x not in actual])}], but got {actual}"""

    def spin_on(unit):
      while True:
        info = machine.get_unit_info(unit, "alice")
        if info["ActiveState"] == "inactive":
          return

    # Create a persistent login so that Alice has a systemd session.
    login_as_alice()

    # Set up a home-manager channel.
    succeed_as_alice(" ; ".join([
      "mkdir -p /home/alice/.nix-defexpr/channels",
      f"ln -s {home_manager} /home/alice/.nix-defexpr/channels/home-manager"
    ]))

    with subtest("Home Manager installation"):
      succeed_as_alice("nix-shell \"<home-manager>\" -A install")

    succeed_as_alice("cp ${./restic-home.nix} /home/alice/.config/home-manager/home.nix")

    succeed_as_alice("cp -rT ${testDir} /home/alice/files")
    succeed_as_alice("cp -rT ${dynDir} /home/alice/dyn-files")
    succeed_as_alice("echo password123 > /home/alice/password")

    succeed_as_alice("home-manager switch")

    expectedIncluded = [
      "/home",
      "/home/alice",
      "/home/alice/files",
      "/home/alice/files/a_dir",
      "/home/alice/files/a_dir/a_file",
      "/home/alice/files/a_dir/a_file_2",
      "/home/alice/files/some_file",
      "/home/alice/files/some_other_file"
    ]

    with subtest("Basic backup"):
      systemctl_succeed_as_alice("start restic-backups-basic.service")
      actual = succeed_as_alice("restic-basic ls latest")
      assert_list("restic-basic ls latest", expectedIncluded, actual)

      assert "exclude" not in actual, \
        f"Paths containing \"*exclude*\" got backed up incorrectly. output: {actual}"

    with subtest("Basic restore"):
      succeed_as_alice("restic-basic restore latest --target restore/basic")
      actual = fail_as_alice("diff -urNa restore/basic/home/alice/files files")
      expected1 = "alices-secret-diary"
      expected2 = "alices-bank-details"
      assert expected1 in actual and expected2 in actual, \
        f"expected diff -ur restore/basic/home/alice/files files to contain \
          {expected1} and {expected2}, but got {actual}"

    with subtest("Fails to start with an un-initialized repo"):
      systemctl_fail_as_alice("start restic-backups-noinit.service")

    with subtest("Start with an initialized repo"):
      succeed_as_alice("restic-noinit init")
      systemctl_succeed_as_alice("start restic-backups-noinit.service")

    with subtest("Using a repositoryFile"):
      systemctl_succeed_as_alice("start restic-backups-repo-file.service")
      actual = succeed_as_alice("restic-repo-file ls latest")
      assert_list("restic-repo-file ls latest", expectedIncluded, actual)

      assert "exclude" not in actual, \
        f"Paths containing \"*exclude*\" got backed up incorrectly. output: {actual}"

    with subtest("Using an rclone backend"):
      systemctl_succeed_as_alice("start restic-backups-rclone.service")
      actual = succeed_as_alice("restic-rclone ls latest")
      assert_list("restic-rclone ls latest", expectedIncluded, actual)

      assert "exclude" not in actual, \
        f"Paths containing \"*exclude*\" got backed up incorrectly. output: {actual}"

    with subtest("Backup with prepare and cleanup commands"):
      systemctl_succeed_as_alice("start restic-backups-pre-post-jobs.service")
      actual = succeed_as_alice("journalctl --no-pager --user -u restic-backups-pre-post-jobs.service")

      expected_list = [
        "Preparing Backup...",
        "Notifying Alice...",
        "Ready!",
        "Finishing Backup...",
        "Mailing alice the results...",
        "Done."
      ]
      assert_list("journalctl --no-pager --user -u restic-backups-pre-post-jobs.service", \
                  expected_list, \
                  actual)

    expectedIncludedDyn = expectedIncluded + [
      "/home/alice/dyn-files",
      "/home/alice/dyn-files/a_dir",
      "/home/alice/dyn-files/a_dir/a_file",
      "/home/alice/dyn-files/a_dir/a_file_2",
      "/home/alice/dyn-files/metadata",
      "/home/alice/dyn-files/some_file",
      "/home/alice/dyn-files/some_other_file"
    ]

    with subtest("Dynamic paths"):
      systemctl_succeed_as_alice("start restic-backups-dynamic-paths.service")
      actual = succeed_as_alice("restic-dynamic-paths ls latest")
      assert_list("restic-dynamic-paths ls latest", expectedIncludedDyn, actual)

      assert "secret" not in actual, \
        f"Paths containing \"*secret*\" got backed up incorrectly. output: {actual}"

    with subtest("Inhibit Sleep"):
      # Gives us some time to grep systemd-inhibit before exiting
      succeed_as_alice(
        "chmod +w /home/alice/files",
        # 100MB
        "dd if=/dev/urandom of=/home/alice/files/bigfile status=none bs=4096 count=25600"
      )

      systemctl_succeed_as_alice("start --no-block restic-backups-inhibits-sleep.service")
      machine.wait_until_succeeds("systemd-inhibit --no-legend --no-pager | grep -q restic", 30)
      spin_on("restic-backups-inhibits-sleep.service")

      actual = succeed_as_alice("restic-inhibits-sleep ls latest")
      assert_list("restic-inhibits-sleep ls latest", expectedIncluded, actual)

      assert "exclude" not in actual, \
        f"Paths containing \"*exclude*\" got backed up incorrectly. output: {actual}"

      succeed_as_alice("rm /home/alice/files/bigfile")

    with subtest("Create a few backups at different times"):
      snapshot_count = 0

      def make_backup(time):
        global snapshot_count
        machine.succeed(f"timedatectl set-time '{time}'")
        systemctl_succeed_as_alice("start restic-backups-prune-me.service")
        snapshot_count += 1
        actual = \
          succeed_as_alice("restic-prune-me snapshots --json | ${lib.getExe pkgs.jq} length")
        assert int(actual) == snapshot_count, \
          f"Expected a snapshot count of {snapshot_count} but got {actual}"

      # a year with 3 snapshots
      make_backup("1970-01-01 12:34")
      make_backup("1970-06-01 12:34")
      make_backup("1970-12-01 12:34")
      # a year with 2
      make_backup("1971-02-11 12:34")
      make_backup("1971-03-10 12:34")
      # a year with 3
      make_backup("1972-01-02 12:34")
      make_backup("1972-03-01 12:34")
      make_backup("1972-04-02 12:34")
      # a month with 2
      make_backup("1973-04-01 12:34")
      make_backup("1973-04-02 12:34")
      # a week with 3
      make_backup("1973-06-4 12:34")
      make_backup("1973-06-6 12:56")
      make_backup("1973-06-9 12:56")
      # a week with 2
      make_backup("1973-06-12 12:56")
      make_backup("1973-06-13 12:56")
      # a day with 3
      make_backup("1973-06-18 01:00")
      make_backup("1973-06-18 12:25")
      make_backup("1973-06-18 23:01")
      # an hour with 3
      make_backup("1973-06-19 21:11")
      make_backup("1973-06-19 21:31")
      make_backup("1973-06-19 21:41")
      # an hour with 2
      make_backup("1973-06-19 23:10")
      make_backup("1973-06-19 23:30")

    with subtest("Prune snapshots"):
      systemctl_succeed_as_alice("start restic-backups-prune-only.service")
      actual = \
        succeed_as_alice("restic-prune-only snapshots --json | ${lib.getExe pkgs.jq} length")
      assert int(actual) == 8, \
        f"Expected a snapshot count of 8 but got {actual}"

    with subtest("Prune opts"):
      systemctl_succeed_as_alice("start restic-backups-prune-opts.service")

    with subtest("Environment file"):
      systemctl_succeed_as_alice("start restic-backups-env-file.service")
      actual = succeed_as_alice("restic-env-file ls latest")
      assert_list("restic-env-file ls latest", expectedIncluded, actual)

      assert "exclude" not in actual, \
        f"Paths containing \"*exclude*\" got backed up incorrectly. output: {actual}"

    logout_alice()
  '';
}
