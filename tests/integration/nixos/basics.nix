{ lib, pkgs, ... }:

{
  name = "nixos-basics";
  meta.maintainers = [ pkgs.lib.maintainers.rycee ];

  nodes.machine =
    { config, pkgs, ... }:
    let
      inherit (config.home-manager.users) bob;
    in
    {
      imports = [ ../../../nixos ]; # Import the HM NixOS module.

      security.pam.services = {
        chpasswd = { };
        passwd = { };
      };

      system.activationScripts.addBobUser =
        lib.fullDepEntry
          ''
            ${pkgs.shadow}/bin/useradd \
              --comment 'Manually-created user' \
              --create-home --no-user-group \
              --gid ${lib.escapeShellArg config.users.groups.users.name} \
              --home-dir ${lib.escapeShellArg bob.home.homeDirectory} \
              --no-user-group \
              --shell ${lib.escapeShellArg (lib.getExe config.users.defaultUserShell)} \
              ${lib.escapeShellArg bob.home.username}
          ''
          [
            "groups"
            "users"
          ];

      virtualisation.memorySize = 2048;

      # To be able to add the `bob` account with `useradd`.
      users.mutableUsers = true;

      users.users.alice = {
        isNormalUser = true;
        description = "Alice Foobar";
        uid = 1000;
      };

      home-manager.useUserPackages = true;

      home-manager.users =
        let
          common = {
            home.stateVersion = "24.11";
            home.file.test.text = "testfile";
            home.packages = [ pkgs.hello ];
            # Enable a light-weight systemd service.
            services.pueue.enable = true;
          };
        in
        {
          alice = common;

          # User without corresponding entry in `users.users`.
          bob =
            { name, ... }:
            {
              imports = [ common ];
              home.stateVersion = "24.11";
              home.username = lib.mkForce name;
              home.homeDirectory = lib.mkForce "/var/tmp/hm/home/bob";
              home.useUserPackages = false;
            };
        };
    };

  testScript =
    { nodes, ... }:
    let
      inherit (nodes.machine.home-manager.users) alice bob;
      password = "foobar";
    in
    ''
      import pprint
      from contextlib import contextmanager
      from typing import Callable, Dict, Optional

      def wait_for_unit_properties(
        machine: Machine, unit: str, check: Callable[[Dict[str, str]], Dict[str, Optional[str]]], user: Optional[str] = None, timeout: int = 900,
      ) -> None:
        def unit_has_properties(_):
          info = machine.get_unit_info(unit, user)
          mismatches = check(info)
          if mismatches == {}:
            return True
          else:
            machine.log(f"unit {unit} has unexpected properties {pprint.pformat(mismatches)}")
            return False

        with machine.nested(f"waiting for unit {unit} to satisfy expected properties"):
          retry(unit_has_properties, timeout)

      def wait_for_oneshot_successful_completion(
        machine: Machine, unit: str, user: Optional[str] = None, timeout: int = 900
      ) -> None:
        def unit_is_successfully_completed_oneshot(info: Dict[str, str]) -> Dict[str, Optional[str]]:
          assert "Type" in info, f"unit {unit}'s properties include 'Type'"
          assert info["Type"] == "oneshot", f"expected unit {unit}'s 'Type' to be 'oneshot'; got {info['Type']}"

          props = ["ActiveState", "Result", "SubState"]

          if all([prop in info for prop in props]):
            if "RemainAfterExit" in info and info["RemainAfterExit"] == "yes":
              if info["ActiveState"] == "active" and info["Result"] == "success" and info["SubState"] == "exited":
                return {}
            elif info["ActiveState"] == "inactive" and info["Result"] == "success" and info["SubState"] == "dead":
              return {}

          return {prop: info.get(prop) for prop in props}

        return wait_for_unit_properties(
          machine, unit, unit_is_successfully_completed_oneshot, user=user, timeout=timeout
        )

      @contextmanager
      def user_login(machine: Machine, user: str, password: str):
        machine.wait_until_tty_matches("1", "login: ")
        machine.send_chars(f"{user}\n")
        machine.wait_until_tty_matches("1", "Password: ")
        machine.send_chars(f"{password}\n")
        machine.wait_until_tty_matches("1", f"{user}\\@{machine.name}")

        try:
          yield
        finally:
          machine.send_chars("exit\n")

      def cmd_for_user(user: str, cmd: str) -> str:
        return f"su -l {user} --shell /bin/sh -c $'export XDG_RUNTIME_DIR=/run/user/$UID ; {cmd}'"

      def succeed_as_user(user: str, cmd: str) -> str:
        return machine.succeed(cmd_for_user(user, cmd))

      def fail_as_user(user: str, cmd: str) -> str:
        return machine.fail(cmd_for_user(user, cmd))

      start_all()

      for user in ["${alice.home.username}", "${bob.home.username}"]:
        user_hm_unit = f"home-manager-{user}.service"
        wait_for_oneshot_successful_completion(machine, user_hm_unit)

        machine.succeed(f"echo '{user}:${password}' | ${pkgs.shadow}/bin/chpasswd")

        with subtest(f"Home Manager file (user {user})"):
          # The file should be linked with the expected content.
          path = f"~{user}/test"
          machine.succeed(f"test -L {path}")
          actual = machine.succeed(f"cat {path}")
          expected = "testfile"
          assert actual == expected, f"expected {path} to contain {expected}, but got {actual}"

        with subtest(f"Command from `home.packages` (user {user})"):
          succeed_as_user(user, "hello")

        with subtest(f"Pueue service (user {user})"):
          with user_login(machine, user, "${password}"):
            actual = succeed_as_user(user, "pueue status")
            expected = "running"
            assert expected in actual, f"expected pueue status to contain {expected}, but got {actual}"

            # Shut down pueue, then run the activation again. Afterwards, the
            # service should be running.
            machine.succeed(f"systemctl --user -M {user}@.host stop pueued.service")

            fail_as_user(user, "pueue status")

            machine.systemctl(f"restart {user_hm_unit}")
            wait_for_oneshot_successful_completion(machine, user_hm_unit)

            actual = succeed_as_user(user, "pueue status")
            expected = "running"
            assert expected in actual, f"expected pueue status to contain {expected}, but got {actual}"

        with subtest(f"GC root and profile (user {user})"):
          # There should be a GC root and Home Manager profile and they should
          # point to the same path in the Nix store.
          gcroot = f"~{user}/.local/state/home-manager/gcroots/current-home"
          gcrootTarget = machine.succeed(f"readlink {gcroot}")

          profile = f"~{user}/.local/state/nix/profiles"
          profileTarget = machine.succeed(f"readlink {profile}/home-manager")
          profile1Target = machine.succeed(f"readlink {profile}/{profileTarget}")

          assert gcrootTarget == profile1Target, \
            f"expected GC root and profile to point to same, but pointed to {gcrootTarget} and {profile1Target}"
    '';
}
