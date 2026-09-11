{
  config,
  genericLinuxRecoveryScalarMode,
  lib,
  realPkgs,
  ...
}:

let
  hasConfiguredScalars = genericLinuxRecoveryScalarMode != "discovered";
  hasZshScalarOverrides = genericLinuxRecoveryScalarMode == "zsh";

  runtimeCertificate = realPkgs.runCommand "hm-recovery-runtime-certificate" { } ''
    mkdir -p $out/etc/ssl/certs
    touch $out/etc/ssl/certs/ca-bundle.crt
  '';

  expectedGenericProfiles =
    {
      home = "configured-profiles";
      zsh = "home-profiles";
    }
    .${genericLinuxRecoveryScalarMode} or null;
  expectedGenericCertificate =
    {
      home = "/configured/ca.pem";
      zsh = "/home/ca.pem";
    }
    .${genericLinuxRecoveryScalarMode} or null;
  expectedZshProfiles =
    if hasZshScalarOverrides then "`printf zsh-profiles`" else expectedGenericProfiles;
  expectedZshCertificate = if hasZshScalarOverrides then "" else expectedGenericCertificate;
in
{
  config = {
    targets.genericLinux.enable = true;

    # Use real package metadata to select the same profile policy as Nix.
    # The default NMT package scrubber replaces pkgs.nix with a marker.
    test.unstubs = [ (_self: _super: { inherit (realPkgs) nix; }) ];

    programs = {
      bash = {
        enable = true;
        enableCompletion = false;
      };
      fish = {
        enable = true;
        generateCompletions = false;
        package = realPkgs.fish;
      };
      zsh = {
        enable = true;
        sessionVariables = {
          SELF_REFERENTIAL = "$SELF_REFERENTIAL/suffix";
        }
        // lib.optionalAttrs (genericLinuxRecoveryScalarMode == "home") {
          NIX_PROFILES = null;
          NIX_SSL_CERT_FILE = null;
        }
        // lib.optionalAttrs hasZshScalarOverrides {
          NIX_PROFILES = "`printf zsh-profiles`";
          NIX_SSL_CERT_FILE = "";
        };
      };
    };

    home.sessionVariables =
      lib.optionalAttrs (genericLinuxRecoveryScalarMode == "home") {
        NIX_PROFILES = "`printf configured-profiles`";
        NIX_SSL_CERT_FILE = "\${NIX_SSL_CERT_FILE:-\"/configured/ca.pem\"}";
      }
      // lib.optionalAttrs hasZshScalarOverrides {
        NIX_PROFILES = "home-profiles";
        NIX_SSL_CERT_FILE = "/home/ca.pem";
      };

    home.sessionVariablesExtra = ''
      EXTRA_RUNS="''${EXTRA_RUNS-}x"
      export EXTRA_RUNS
    '';

    home.packages = [
      (realPkgs.writeShellScriptBin "hm-recovery-command" "exit 0")
      runtimeCertificate
    ];

    test.asserts.warnings.expected = [
      ''
        The following programs.zsh.sessionVariables may change when applied again:

          SELF_REFERENTIAL, defined in `${toString ./generic-linux-recovery.nix}'

        Home Manager reapplies these values after the generated session
        variables change, so self-referential values can change again.

        For search paths, use home.sessionPath,
        home.sessionSearchVariables, or home.sessionSearchVariablesAppend.
        Those options add only the entries that are missing. For other
        variables, assign a complete value without referring to its previous
        contents.

        This check is best-effort and detects only direct parameter references
        such as $NAME, ''${NAME...}, and ''${#NAME}.
      ''
    ];

    nmt.script = ''
      set -eu
      failures=0

      runtimeHome="$TMPDIR/generic-linux-recovery-home"
      ${realPkgs.coreutils}/bin/rm -rf "$runtimeHome"
      ${realPkgs.coreutils}/bin/mkdir -p "$runtimeHome"
      ${realPkgs.coreutils}/bin/cp "$TESTED/home-files/.bash_profile" "$runtimeHome/.bash_profile"
      ${realPkgs.coreutils}/bin/cp "$TESTED/home-files/.bashrc" "$runtimeHome/.bashrc"
      ${realPkgs.coreutils}/bin/cp "$TESTED/home-files/.profile" "$runtimeHome/.profile"
      ${realPkgs.coreutils}/bin/cp "$TESTED/home-files/.zshenv" "$runtimeHome/.zshenv"
      ${realPkgs.coreutils}/bin/cp -R "$TESTED/home-files/.config" "$runtimeHome/.config"
      ${realPkgs.coreutils}/bin/ln -s "$TESTED/home-path" "$runtimeHome/.nix-profile"

      nixEnvironment=${config.targets.genericLinux.nixEnvironmentPackage}/etc/profile.d/hm-nix-env.sh
      assertFileContains "$nixEnvironment" 'NIX_STATE_HOME'
      assertFileContains \
        ${config.targets.genericLinux.nixEnvironmentPackage}/etc/profile.d/hm-nix-env.fish \
        'NIX_STATE_HOME'

      # Standard Nix 2.25 and newer selects NIX_STATE_HOME before the legacy
      # and XDG profile locations. The resolver also preserves explicitly set
      # empty scalar values on later refreshes.
      ${realPkgs.coreutils}/bin/mkdir -p "$runtimeHome/nix-state"
      ${realPkgs.coreutils}/bin/ln -s "$TESTED/home-path" "$runtimeHome/nix-state/profile"
      ${realPkgs.coreutils}/bin/env -i \
        HOME="$runtimeHome" NIX_STATE_HOME="$runtimeHome/nix-state" \
        PATH=/usr/bin:/bin XDG_DATA_DIRS=/fixture MANPATH=/usr/share/man: \
        ${realPkgs.bash}/bin/bash --noprofile --norc -c '
          . "$1"
          [ "$NIX_PROFILES" = "/nix/var/nix/profiles/default $NIX_STATE_HOME/profile" ] || exit 1
          [ -n "$NIX_SSL_CERT_FILE" ] || exit 1
          [ "$MANPATH" = "$NIX_STATE_HOME/profile/share/man:/usr/share/man:" ] || exit 1
          case ":$PATH:" in
            *":/home/hm-user/.nix-profile/bin:"*) ;;
            *) exit 1 ;;
          esac
          case ":$PATH:" in
            *":$NIX_STATE_HOME/profile/bin:"*) ;;
            *) exit 1 ;;
          esac
          NIX_PROFILES=
          NIX_SSL_CERT_FILE=
          export NIX_PROFILES NIX_SSL_CERT_FILE
          . "$1"
          [ "''${NIX_PROFILES+x}:$NIX_PROFILES" = x: ] || exit 1
          [ "''${NIX_SSL_CERT_FILE+x}:$NIX_SSL_CERT_FILE" = x: ] || exit 1
        ' shell "$nixEnvironment" \
        || fail "Nix 2.25 profile selection or scalar preservation failed"

      # Cold startup establishes the runtime profile using a HOME that differs
      # from HM's configured home. Configured scalar values take precedence
      # over values that the Nix profile script would discover.
      ${realPkgs.coreutils}/bin/env -i \
        HOME="$runtimeHome" USER=hm-user TMPDIR="$TMPDIR" \
        PATH=/usr/bin:/bin MANPATH=/usr/share/man: \
        ${realPkgs.bash}/bin/bash --noprofile --norc -c '
          printf "%s\n" BASH_COLD_START
          . "$HOME/.bash_profile"
          ${
            if hasConfiguredScalars then
              ''
                [ "$NIX_PROFILES" = ${lib.escapeShellArg expectedGenericProfiles} ] || exit 1
                [ "$NIX_SSL_CERT_FILE" = ${lib.escapeShellArg expectedGenericCertificate} ] || exit 1
              ''
            else
              ''
                [ "$NIX_PROFILES" = "/nix/var/nix/profiles/default $HOME/.nix-profile" ] || exit 1
                [ -n "$NIX_SSL_CERT_FILE" ] || exit 1
              ''
          }
          [ "$MANPATH" = "$HOME/.nix-profile/share/man:/usr/share/man:" ] || exit 1
          [ "$(command -v hm-recovery-command)" = "$HOME/.nix-profile/bin/hm-recovery-command" ] || exit 1
          [ "$EXTRA_RUNS" = x ] || exit 1

          # Retain the exported markers while simulating a login environment
          # that lost the values established by nix.sh.
          unset NIX_PROFILES NIX_SSL_CERT_FILE
          PATH=/usr/bin:/bin
          unset XDG_DATA_DIRS
          MANPATH=/usr/share/man:
          printf "%s\n" BASH_RECOVERY_START
          . "$HOME/.bash_profile"
          ${
            if hasConfiguredScalars then
              ''
                [ "$NIX_PROFILES" = ${lib.escapeShellArg expectedGenericProfiles} ] || exit 1
                [ "$NIX_SSL_CERT_FILE" = ${lib.escapeShellArg expectedGenericCertificate} ] || exit 1
              ''
            else
              ''
                [ "$NIX_PROFILES" = "/nix/var/nix/profiles/default $HOME/.nix-profile" ] || exit 1
                [ -n "$NIX_SSL_CERT_FILE" ] || exit 1
              ''
          }
          [ "$MANPATH" = "$HOME/.nix-profile/share/man:/usr/share/man:" ] || exit 1
          [ "$(command -v hm-recovery-command)" = "$HOME/.nix-profile/bin/hm-recovery-command" ] || exit 1
          [ "$EXTRA_RUNS" = x ] || exit 1
          for entry in \
            /nix/var/nix/profiles/default/share \
            /home/hm-user/.nix-profile/share \
            "$HOME/.nix-profile/share"
          do
            count=$(printf "%s" "$XDG_DATA_DIRS" | ${realPkgs.coreutils}/bin/tr : "\n" | ${realPkgs.gnugrep}/bin/grep -cFx "$entry")
            [ "$count" = 1 ] || exit 1
          done
        ' \
        || {
          echo "BASH_RECOVERY_FAILED"
          failures=1
        }

      # Recovery must preserve the position of an existing profile entry.
      ${realPkgs.coreutils}/bin/mkdir -p "$runtimeHome/precedence"
      ${realPkgs.coreutils}/bin/ln -s "$runtimeHome/.nix-profile/bin/hm-recovery-command" \
        "$runtimeHome/precedence/hm-recovery-command"
      ${realPkgs.coreutils}/bin/env -i \
        HOME="$runtimeHome" USER=hm-user TMPDIR="$TMPDIR" \
        PATH="$runtimeHome/precedence:$runtimeHome/.nix-profile/bin:/usr/bin:/bin" MANPATH=/usr/share/man: \
        __HM_SESS_VARS_SOURCED=1 __HM_SESS_VARS_MERGED=1 \
        ${realPkgs.bash}/bin/bash --noprofile --norc -c '
          . "$HOME/.bash_profile"
          [ "$(command -v hm-recovery-command)" = "$HOME/precedence/hm-recovery-command" ] || exit 1
        ' \
        || {
          echo "BASH_PRECEDENCE_FAILED"
          failures=1
        }

      # Zsh does not run .zshenv when invoked with -f, so source the generated
      # startup explicitly in both shells. The unchanged token permits generic
      # recovery but must not evaluate the self-reference twice.
      ${realPkgs.coreutils}/bin/env -i \
        HOME="$runtimeHome" USER=hm-user TMPDIR="$TMPDIR" \
        PATH=/usr/bin:/bin MANPATH=/usr/share/man: SELF_REFERENTIAL=base \
        EXPECTED_ZSH_PROFILES=${
          lib.escapeShellArg (if hasConfiguredScalars then expectedZshProfiles else "")
        } \
        EXPECTED_ZSH_CERTIFICATE=${
          lib.escapeShellArg (if hasConfiguredScalars then expectedZshCertificate else "")
        } \
        ${realPkgs.zsh}/bin/zsh -f -c '
          print ZSH_COLD_START
          source "$HOME/.zshenv"
          ${
            if hasConfiguredScalars then
              ''
                [ "$NIX_PROFILES" = "$EXPECTED_ZSH_PROFILES" ] || exit 1
                [ "$NIX_SSL_CERT_FILE" = "$EXPECTED_ZSH_CERTIFICATE" ] || exit 1
              ''
            else
              ''
                [ "$NIX_PROFILES" = "/nix/var/nix/profiles/default $HOME/.nix-profile" ] || exit 1
                [ -n "$NIX_SSL_CERT_FILE" ] || exit 1
              ''
          }
          [ "$SELF_REFERENTIAL" = base/suffix ] || exit 1
          unset NIX_PROFILES NIX_SSL_CERT_FILE
          PATH=/usr/bin:/bin
          unset XDG_DATA_DIRS
          MANPATH=/usr/share/man:
          print ZSH_RECOVERY_START
          ${realPkgs.coreutils}/bin/env \
            -u NIX_PROFILES -u NIX_SSL_CERT_FILE -u XDG_DATA_DIRS \
            HOME="$HOME" USER=hm-user TMPDIR="$TMPDIR" \
            PATH="$PATH" MANPATH="$MANPATH" \
            SELF_REFERENTIAL="$SELF_REFERENTIAL" \
            EXPECTED_ZSH_PROFILES="$EXPECTED_ZSH_PROFILES" \
            EXPECTED_ZSH_CERTIFICATE="$EXPECTED_ZSH_CERTIFICATE" \
            __HM_ZSH_SESS_VARS_SOURCED="$__HM_ZSH_SESS_VARS_SOURCED" \
            ${realPkgs.zsh}/bin/zsh -f -c "
              source \"\$HOME/.zshenv\"
              ${
                if hasConfiguredScalars then
                  ''
                    [ \"\$NIX_PROFILES\" = \"\$EXPECTED_ZSH_PROFILES\" ] || exit 1
                    [ \"\$NIX_SSL_CERT_FILE\" = \"\$EXPECTED_ZSH_CERTIFICATE\" ] || exit 1
                  ''
                else
                  ''
                    [ \"\$NIX_PROFILES\" = \"/nix/var/nix/profiles/default \$HOME/.nix-profile\" ] || exit 1
                    [ -n \"\$NIX_SSL_CERT_FILE\" ] || exit 1
                  ''
              }
              [ \"\$MANPATH\" = \"\$HOME/.nix-profile/share/man:/usr/share/man:\" ] || exit 1
              [ \"\$SELF_REFERENTIAL\" = base/suffix ] || exit 1
              [ \"\$(command -v hm-recovery-command)\" = \"\$HOME/.nix-profile/bin/hm-recovery-command\" ] || exit 1
              for entry in \
                /nix/var/nix/profiles/default/share \
                /home/hm-user/.nix-profile/share \
                \"\$HOME/.nix-profile/share\"
              do
                count=\$(printf \"%s\" \"\$XDG_DATA_DIRS\" | ${realPkgs.coreutils}/bin/tr : \"\\n\" | ${realPkgs.gnugrep}/bin/grep -cFx \"\$entry\")
                [ \"\$count\" = 1 ] || exit 1
              done
            "
        ' \
        || {
          echo "ZSH_RECOVERY_FAILED"
          failures=1
        }

      fishConfig="$runtimeHome/.config/fish/config.fish"
      assertFileExists "$fishConfig"

      # Seed Fish's native startup, then launch a child with the exported
      # Home Manager session guards intact and runtime values removed.
      ${realPkgs.coreutils}/bin/env -i \
        HOME="$runtimeHome" USER=hm-user TMPDIR="$TMPDIR" \
        PATH=/usr/bin:/bin MANPATH=/usr/share/man: \
        ${realPkgs.fish}/bin/fish --no-config -c '
          echo FISH_COLD_START
          source $argv[1]
          ${
            if hasConfiguredScalars then
              ''
                test "$NIX_PROFILES" = ${lib.escapeShellArg expectedGenericProfiles}; or exit 1
                test "$NIX_SSL_CERT_FILE" = ${lib.escapeShellArg expectedGenericCertificate}; or exit 1
              ''
            else
              ''
                test "$NIX_PROFILES" = "/nix/var/nix/profiles/default $HOME/.nix-profile"; or exit 1
                test -n "$NIX_SSL_CERT_FILE"; or exit 1
              ''
          }
          test "$MANPATH" = "$HOME/.nix-profile/share/man:/usr/share/man:"; or exit 1
          type -q hm-recovery-command; or exit 1
          test "$EXTRA_RUNS" = x; or exit 1
          set -gx __HM_SESS_VARS_SOURCED "$__HM_SESS_VARS_SOURCED"
          set -e NIX_PROFILES
          set -e NIX_SSL_CERT_FILE
          set -gx PATH /usr/bin /bin
          set -e XDG_DATA_DIRS
          set -gx MANPATH /usr/share/man ""
          echo FISH_RECOVERY_START
          ${realPkgs.fish}/bin/fish --no-config -c "
            source \"\$argv[1]\"
            ${
              if hasConfiguredScalars then
                ''
                  test \"\$NIX_PROFILES\" = ${lib.escapeShellArg expectedGenericProfiles}; or exit 1
                  test \"\$NIX_SSL_CERT_FILE\" = ${lib.escapeShellArg expectedGenericCertificate}; or exit 1
                ''
              else
                ''
                  test \"\$NIX_PROFILES\" = \"/nix/var/nix/profiles/default \$HOME/.nix-profile\"; or exit 1
                  test -n \"\$NIX_SSL_CERT_FILE\"; or exit 1
                ''
            }
            test \"\$MANPATH\" = \"\$HOME/.nix-profile/share/man:/usr/share/man:\"; or exit 1
            type -q hm-recovery-command; or exit 1
            test \"\$EXTRA_RUNS\" = x; or exit 1
            for entry in \
              /nix/var/nix/profiles/default/share \
              /home/hm-user/.nix-profile/share \
              \"\$HOME/.nix-profile/share\"
              set count (string split : -- \"\$XDG_DATA_DIRS\" | string match -e -- \"\$entry\" | count)
              test \"\$count\" = 1; or exit 1
            end
          " "$argv[1]"
        ' "$fishConfig" \
        || {
          echo "FISH_RECOVERY_FAILED"
          failures=1
        }

      [ "$failures" -eq 0 ] || fail "Generic Linux recovery shell checks failed"
    '';
  };
}
