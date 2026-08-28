{ lib, pkgs, ... }:
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

    programs.bash.enable = true;

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
        '. "${pkgs.nix}/etc/profile.d/nix.sh"'

      assertFileContains \
        home-path/etc/profile.d/hm-session-vars.sh \
        'export TERM="$TERM"'

      # nix.sh is not idempotent, so it must appear exactly once and must not
      # be repeated in .bashrc, which now re-sources the session variables
      # file on every interactive shell.
      assertFileExists home-files/.bashrc
      assertFileNotRegex home-files/.bashrc 'profile\.d/nix\.sh'
      nixShCount=$(grep -c 'profile\.d/nix\.sh' \
        "$TESTED/home-path/etc/profile.d/hm-session-vars.sh")
      [ "$nixShCount" = 1 ] \
        || fail "nix.sh referenced $nixShCount times in hm-session-vars.sh"

      # Behavioural: applying the file twice must still run nix.sh once,
      # because it lives in the guarded section.
      printf '%s\n' \
        'NIX_SH_RUNS=$(( ''${NIX_SH_RUNS:-0} + 1 ))' \
        'export NIX_SH_RUNS' \
        > "$TMPDIR/fake-nix.sh"
      sed "s|\. \"${pkgs.nix}/etc/profile.d/nix.sh\"|. \"$TMPDIR/fake-nix.sh\"|" \
        "$TESTED/home-path/etc/profile.d/hm-session-vars.sh" > "$TMPDIR/sessvars.sh"
      grep -q 'fake-nix.sh' "$TMPDIR/sessvars.sh" \
        || fail "could not substitute the nix.sh stand-in"

      env -u __HM_SESS_VARS_SOURCED -u NIX_SH_RUNS \
        TERM=dumb "$BASH" --noprofile --norc -c '
          . "$1"
          . "$1"
          [ "$NIX_SH_RUNS" = 1 ] \
            || { echo "nix.sh ran $NIX_SH_RUNS times"; exit 1; }
          exit 0
        ' shell "$TMPDIR/sessvars.sh" \
        || fail "nix.sh was not sourced exactly once"
    '';
  };
}
