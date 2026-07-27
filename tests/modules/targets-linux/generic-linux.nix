{
  config,
  lib,
  ...
}:
let
  xdgDataDirEntries = [
    "\${NIX_STATE_DIR:-/nix/var/nix}/profiles/default/share"
    "/home/hm-user/.nix-profile/share"
    "/usr/share/ubuntu"
    "/usr/local/share"
    "/usr/share"
    "/var/lib/snapd/desktop"
    "/foo"
  ];

  expectedXdgDataDirs = lib.concatStringsSep ":" xdgDataDirEntries;

  # The runtime environment below starts with these entries.
  inheritedXdgDataDirs = [
    "/flatpak/share"
    "/usr/share"
  ];

  # `/usr/share` is already inherited, so it keeps its position instead of
  # being prepended. The stub `nix.sh` appends its own entry last.
  expectedRuntimeXdgDataDirs = lib.concatStringsSep ":" (
    lib.remove "/usr/share" (
      lib.map (lib.replaceStrings
        [ "\${NIX_STATE_DIR:-/nix/var/nix}" ]
        [ "/nix/var/nix" ]
      ) xdgDataDirEntries
    )
    ++ inheritedXdgDataDirs
    ++ [ "/nix-profile/share" ]
  );
in
{
  config = {
    targets.genericLinux.enable = true;

    programs.bash = {
      enable = true;
      enableCompletion = false;
    };

    nix.package = config.lib.test.mkStubPackage {
      name = "nix-with-session-script";
      buildScript = ''
        mkdir -p "$out/etc/profile.d"
        cat > "$out/etc/profile.d/nix.sh" <<'EOF'
        NIX_SH_SOURCES=$(( ''${NIX_SH_SOURCES:-0} + 1 ))
        export NIX_SH_SOURCES
        export PATH="/nix-profile/bin''${PATH:+:}$PATH"
        export XDG_DATA_DIRS="''${XDG_DATA_DIRS:+$XDG_DATA_DIRS:}/nix-profile/share"
        EOF
      '';
    };

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
        '. "${config.nix.package}/etc/profile.d/nix.sh"'

      assertFileContains \
        home-path/etc/profile.d/hm-session-vars.sh \
        'export TERM="$TERM"'

      # A login shell reads .profile and then .bashrc. nix.sh must still run
      # only once even though generic Linux re-sources hm-session-vars.sh from
      # Bash initialization.
      # NMT runs this script with Bash, so no separate real package is needed.
      bashBin="$BASH"
      testBashrc=$TMPDIR/test-bashrc
      sed \
        "s|${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh|$TESTED/$sessionVarsFile|" \
        "$TESTED/home-files/.bashrc" > "$testBashrc"
      HOME="$TESTED/home-files" \
        TEST_BASHRC="$testBashrc" \
        USER="hm-user" \
        TERM="dumb" \
        PATH="/flatpak/bin:/usr/bin" \
        XDG_DATA_DIRS="${lib.concatStringsSep ":" inheritedXdgDataDirs}" \
        "$bashBin" --noprofile --norc -ic '
          . "$HOME/.profile"
          . "$TEST_BASHRC"
          [ "$NIX_SH_SOURCES" = 1 ] || {
            echo "nix.sh source count: $NIX_SH_SOURCES"
            exit 1
          }
          [ "$PATH" = "/nix-profile/bin:/flatpak/bin:/usr/bin" ] || {
            echo "PATH after startup: $PATH"
            exit 1
          }
          [ "$XDG_DATA_DIRS" = "${expectedRuntimeXdgDataDirs}" ] || {
            echo "XDG_DATA_DIRS after startup: $XDG_DATA_DIRS"
            exit 1
          }
        ' || fail "generic Linux sourced nix.sh more than once"

      HOME="$TESTED/home-files" \
        TEST_BASHRC="$testBashrc" \
        USER="hm-user" \
        TERM="dumb" \
        PATH="/flatpak/bin:/usr/bin" \
        XDG_DATA_DIRS="${lib.concatStringsSep ":" inheritedXdgDataDirs}" \
        "$bashBin" --noprofile --norc -ic '
          . "$TEST_BASHRC"
          [ "$NIX_SH_SOURCES" = 1 ] || {
            echo "non-login nix.sh source count: $NIX_SH_SOURCES"
            exit 1
          }
          [ "$PATH" = "/nix-profile/bin:/flatpak/bin:/usr/bin" ] || {
            echo "non-login PATH: $PATH"
            exit 1
          }
          [ "$XDG_DATA_DIRS" = "${expectedRuntimeXdgDataDirs}" ] || {
            echo "non-login XDG_DATA_DIRS: $XDG_DATA_DIRS"
            exit 1
          }
        ' || fail "generic Linux non-login shell did not initialize nix.sh once"
    '';
  };
}
