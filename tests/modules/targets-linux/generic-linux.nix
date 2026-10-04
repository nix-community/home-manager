{
  config,
  lib,
  pkgs,
  ...
}:
let
  expectedXdgDataDirs = lib.concatStringsSep ":" [
    "\${NIX_STATE_DIR:-/nix/var/nix}/profiles/default/share"
    "/home/hm-user/.nix-profile/share"
    "/usr/share/ubuntu"
    "/usr/local/share"
    "/usr/share"
    "/var/lib/snapd/desktop"
    "/foo"
  ];
in
{
  config = {
    targets.genericLinux.enable = true;

    nix.package = pkgs.runCommand "nix-2.24.0" {
      pname = "nix";
      version = "2.24.0";
    } "mkdir -p $out";

    programs.bash = {
      enable = true;
      enableCompletion = false;
    };

    home.packages = [ (pkgs.writeShellScriptBin "hm-profile-command" "exit 0") ];

    home.sessionVariablesExtra = ''
      EXTRA_RUNS="''${EXTRA_RUNS-}x"
      export EXTRA_RUNS
    '';

    xdg.systemDirs.data = [ "/foo" ];

    nmt.script = ''
      envFile=home-files/.config/environment.d/10-home-manager.conf
      assertFileExists $envFile
      assertFileContains $envFile \
        'XDG_DATA_DIRS=${expectedXdgDataDirs}''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}'
      assertFileContains $envFile \
        'TERMINFO_DIRS=/home/hm-user/.nix-profile/share/terminfo:$TERMINFO_DIRS''${TERMINFO_DIRS:+:}/etc/terminfo:/lib/terminfo:/usr/share/terminfo'

      sessionVarsFile=home-path/etc/profile.d/hm-session-vars.sh
      assertFileExists $sessionVarsFile
      assertFileContains $sessionVarsFile \
        '. "${config.targets.genericLinux.nixEnvironmentPackage}/etc/profile.d/hm-nix-env.sh"'
      assertFileNotRegex $sessionVarsFile 'profile\.d/nix\.sh'
      assertFileNotRegex \
        ${config.targets.genericLinux.nixEnvironmentPackage}/etc/profile.d/hm-nix-env.sh \
        'NIX_STATE_HOME'

      assertFileContains \
        home-path/etc/profile.d/hm-session-vars.sh \
        'export TERM="$TERM"'

      # The refresh is repeatable and lives before the arbitrary-extra guard.
      # Bash must not carry a second repair path.
      assertFileExists home-files/.bashrc
      assertFileNotRegex home-files/.bashrc 'hm-nix-env\.sh'
      nixEnvCount=$(grep -c 'profile\.d/hm-nix-env\.sh' \
        "$TESTED/home-path/etc/profile.d/hm-session-vars.sh")
      [ "$nixEnvCount" = 1 ] \
        || fail "Nix refresh referenced $nixEnvCount times in hm-session-vars.sh"

      # Applying the file twice refreshes twice while arbitrary extra code runs
      # only once.
      printf '%s\n' \
        'NIX_ENV_RUNS=$(( ''${NIX_ENV_RUNS:-0} + 1 ))' \
        'export NIX_ENV_RUNS' \
        > "$TMPDIR/fake-nix-env.sh"
      sed "s|\. \"${config.targets.genericLinux.nixEnvironmentPackage}/etc/profile.d/hm-nix-env.sh\"|. \"$TMPDIR/fake-nix-env.sh\"|" \
        "$TESTED/home-path/etc/profile.d/hm-session-vars.sh" > "$TMPDIR/sessvars.sh"
      grep -q 'fake-nix-env.sh' "$TMPDIR/sessvars.sh" \
        || fail "could not substitute the Nix refresh stand-in"

      env -u __HM_SESS_VARS_SOURCED -u NIX_ENV_RUNS -u EXTRA_RUNS \
        TERM=dumb "$BASH" --noprofile --norc -c '
          . "$1"
          . "$1"
          [ "$NIX_ENV_RUNS" = 2 ] \
            || { echo "Nix refresh ran $NIX_ENV_RUNS times"; exit 1; }
          [ "$EXTRA_RUNS" = x ] \
            || { echo "sessionVariablesExtra ran more than once"; exit 1; }
          exit 0
        ' shell "$TMPDIR/sessvars.sh" \
        || fail "Nix refresh and guarded extra code did not repeat correctly"

      ${(import ./generic-linux-runtime.nix) {
        inherit pkgs expectedXdgDataDirs;
      }}
    '';
  };
}
