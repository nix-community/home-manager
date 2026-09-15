{ pkgs, ... }:
let
  home =
    extra:
    (import ../../../modules {
      inherit pkgs;
      configuration = {
        imports = [ extra ];
        home.username = "alice";
        home.homeDirectory = "/home/alice";
        home.stateVersion = "26.05";
        home.file."mutable/base".text = "base";
        manual.manpages.enable = false;
        news.display = "silent";
      };
    }).activationPackage;
  base = home { };
  candidate = home (
    { lib, ... }: {
      home.file."mutable/new" = {
        text = "declared";
        mutable = true;
      };
      home.activation.failAfterCopy = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        if [[ ! -v DRY_RUN && -e "$HOME/fail-after-copy" ]]; then
          echo "injected failure after mutable copy" >&2
          exit 1
        fi
      '';
    }
  );
  disabled = home {
    home.file."mutable/new" = {
      enable = false;
      text = "declared";
      mutable = true;
    };
  };
  putter = home { home.fileActivator = "putter"; };
in
{
  name = "standalone-mutable-files";
  nodes.machine = {
    virtualisation.memorySize = 2048;
    virtualisation.additionalPaths = [
      base
      candidate
      disabled
      putter
    ];
    users.users.alice = {
      isNormalUser = true;
      uid = 1000;
      linger = true;
    };
  };
  testScript = ''
    import shlex

    start_all()
    machine.wait_for_unit("multi-user.target")
    machine.wait_for_unit("user@1000.service")

    def alice(command):
        env = "export XDG_RUNTIME_DIR=/run/user/1000 LC_ALL=C VERBOSE=1; "
        return "su -l alice --shell ${pkgs.bash}/bin/bash -c " + shlex.quote(env + command) + " 2>&1"

    def succeed(command):
        return machine.succeed(alice(command))

    def rejected(command, message):
        status, output = machine.execute(alice(command))
        assert status != 0, output
        assert message in output, output

    def activate(generation, environment=""):
        return environment + " " + generation + "/activate"

    gcroot = "$HOME/.local/state/home-manager/gcroots/current-home"
    succeed("mkdir -p ~/.local/state/nix/profiles ~/.local/state/home-manager/gcroots")

    with subtest("initial successful generation"):
        succeed(activate("${base}"))
        assert succeed(f'readlink -e "{gcroot}"').strip() == "${base}"

    with subtest("dry run does not install or claim new copies"):
        succeed(activate("${candidate}", "DRY_RUN=1"))
        succeed("test ! -e ~/mutable/new")
        assert succeed(f'readlink -e "{gcroot}"').strip() == "${base}"

    with subtest("failure after installing a newly introduced path"):
        succeed("touch ~/fail-after-copy")
        rejected(activate("${candidate}"), "injected failure after mutable copy")
        assert succeed("cat ~/mutable/new") == "declared"
        succeed("test ! -L ~/mutable/new && test -w ~/mutable/new")
        assert succeed(f'readlink -e "{gcroot}"').strip() == "${base}"

    with subtest("retry refuses implicit adoption; backed-up retry preserves edits"):
        succeed("rm ~/fail-after-copy; printf 'edited after failure' > ~/mutable/new")
        rejected(activate("${candidate}"), "would be clobbered")
        succeed(activate("${candidate}", "HOME_MANAGER_BACKUP_EXT=recovery"))
        assert succeed("cat ~/mutable/new.recovery") == "edited after failure"
        assert succeed("cat ~/mutable/new") == "declared"
        assert succeed(f'readlink -e "{gcroot}"').strip() == "${candidate}"

    with subtest("backend switch is rejected before creating Putter state"):
        rejected(activate("${putter}"), "Cannot switch to Putter")
        succeed("test ! -e ~/.local/state/home-manager/putter-state.json")
        assert succeed(f'readlink -e "{gcroot}"').strip() == "${candidate}"

    with subtest("disable last declaration, then switch backend"):
        succeed(activate("${disabled}"))
        succeed("test ! -e ~/mutable/new")
        assert succeed("cat ~/mutable/new.recovery") == "edited after failure"
        succeed(activate("${putter}"))
        succeed("test -L ~/mutable/base")

    with subtest("return to legacy, install again, and roll back"):
        succeed(activate("${base}"))
        succeed(activate("${candidate}"))
        succeed(activate("${base}"))
        succeed("test ! -e ~/mutable/new")
        assert succeed("cat ~/mutable/new.recovery") == "edited after failure"
  '';
}
