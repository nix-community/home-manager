{ config, realPkgs, ... }:
{
  targets.genericLinux.enable = true;
  nix.package = realPkgs.lixPackageSets.latest.lix;

  nmt.script = ''
    runtimeHome="$TMPDIR/lix-profile"
    mkdir -p "$runtimeHome/.nix-profile" "$runtimeHome/state/profile"
    refresh=${config.targets.genericLinux.nixEnvironmentPackage}/etc/profile.d

    for layout in legacy xdg; do
      expected="$runtimeHome/.nix-profile"
      if [ "$layout" = xdg ]; then
        expected="$runtimeHome/xdg/nix/profile"
        mkdir -p "$expected"
      fi

      # Lix uses the existing XDG profile or the legacy profile, even when
      # NIX_STATE_HOME points to another profile.
      ${realPkgs.coreutils}/bin/env -i \
        HOME="$runtimeHome" USER=hm-user \
        PATH=/usr/bin:/bin MANPATH=/usr/share/man: \
        XDG_STATE_HOME="$runtimeHome/xdg" NIX_STATE_HOME="$runtimeHome/state" \
        EXPECTED_PROFILE="$expected" \
        ${realPkgs.bash}/bin/bash --noprofile --norc -c '
          set -eu
          . "$1"
          . "$1"
          [ "$NIX_PROFILES" = "/nix/var/nix/profiles/default $EXPECTED_PROFILE" ]
          [ "$MANPATH" = "$EXPECTED_PROFILE/share/man:/usr/share/man:" ]
          case ":$PATH:" in
            *":$NIX_STATE_HOME/profile/bin:"*) exit 1 ;;
          esac
          case ":$PATH:" in
            *":$EXPECTED_PROFILE/bin:"*) ;;
            *) exit 1 ;;
          esac
        ' shell "$refresh/hm-nix-env.sh" \
        || fail "Lix POSIX profile selection failed for $layout"

      ${realPkgs.coreutils}/bin/env -i \
        HOME="$runtimeHome" USER=hm-user \
        PATH=/usr/bin:/bin MANPATH=/usr/share/man: \
        XDG_STATE_HOME="$runtimeHome/xdg" NIX_STATE_HOME="$runtimeHome/state" \
        EXPECTED_PROFILE="$expected" \
        ${realPkgs.fish}/bin/fish --no-config -c '
          source $argv[1]
          source $argv[1]
          test "$NIX_PROFILES" = "/nix/var/nix/profiles/default $EXPECTED_PROFILE"; or exit 1
          test "$MANPATH" = "$EXPECTED_PROFILE/share/man:/usr/share/man:"; or exit 1
          contains -- "$EXPECTED_PROFILE/bin" $PATH; or exit 1
          not contains -- "$NIX_STATE_HOME/profile/bin" $PATH
        ' "$refresh/hm-nix-env.fish" \
        || fail "Lix Fish profile selection failed for $layout"
    done
  '';
}
