{ config, realPkgs, ... }:

{
  programs.bash = {
    enable = true;
    enableCompletion = false;
    bashrcExtra = ''
      # Anything in .bashrc must be able to override the refreshed values.
      export OVERRIDDEN="from-bashrc"
    '';
    # Bash-owned values must win over generic values after the login shell.
    sessionVariables.SHELL_SPECIFIC = "same-at-login";
    # Bash ownership also applies when the generic value comes from a
    # PATH-like search option rather than home.sessionVariables.
    sessionVariables.BASH_SEARCH = "/bash/search";
    # Null means skip setting, so it must not claim login-layer ownership.
    sessionVariables.NULL_BASH_VALUE = null;
    profileExtra = ''
      export FROM_PROFILE_EXTRA="from-profile-extra"
      export FUTURE_GENERIC="from-profile-extra"
      if [ -n "''${BASH_VERSION-}" ]; then
        declare -ix FUTURE_INTEGER=7
      else
        export FUTURE_INTEGER=7
      fi
      export PROFILE_CHANGED="changed-by-profile"
      unset PROFILE_UNSET
      unset PROFILE_SEARCH
    '';
  };

  home.sessionVariables = {
    REFRESHED = "current";
    OVERRIDDEN = "from-session-vars";
    SHELL_SPECIFIC = "from-session-vars-new";
    FROM_PROFILE_EXTRA = "from-session-vars";
    FUTURE_GENERIC = "from-future-generation";
    FUTURE_INTEGER = "9";
    PROFILE_CHANGED = "from-session-vars";
    PROFILE_UNSET = "from-session-vars";
    NULL_BASH_VALUE = "current";
    # Proves whether the once-per-session section ran.
    EXTRA_MARKER = "unset-by-default";
  };
  home.sessionPath = [ "/hm/bin" ];
  home.sessionSearchVariables = {
    BASH_SEARCH = [ "/hm/bash-search" ];
    PROFILE_SEARCH = [ "/hm/profile-search" ];
  };

  nmt.script = ''
    assertFileExists home-files/.bashrc
    # The refresh must come before bashrcExtra so user code keeps the last word.
    sourceLine=$(grep -n 'hm-session-vars.sh' "$TESTED/home-files/.bashrc" | head -1 | cut -d: -f1)
    extraLine=$(grep -n 'from-bashrc' "$TESTED/home-files/.bashrc" | head -1 | cut -d: -f1)
    [ -n "$sourceLine" ] || fail ".bashrc does not source hm-session-vars.sh"
    [ "$sourceLine" -lt "$extraLine" ] \
      || fail "session variables must be sourced before bashrcExtra ($sourceLine vs $extraLine)"

    # It must be guarded: unguarded sourcing breaks login shells and leaks into
    # the ssh/scp path, since Bash is built with SSH_SOURCE_BASHRC.
    assertFileContains home-files/.bashrc \
      'if [[ $- == *i* ]] && ! shopt -q login_shell; then'

    sessionVarsFile=home-path/etc/profile.d/hm-session-vars.sh
    rewrite() {
      sed "s|${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh|$3|" \
        "$TESTED/home-files/$1" > "$2"
    }
    loginSessionVars=$TMPDIR/login-session-vars.sh
    sed \
      -e 's/export REFRESHED="current"/export REFRESHED="stale"/' \
      -e 's/export NULL_BASH_VALUE="current"/export NULL_BASH_VALUE="stale"/' \
      -e 's/export SHELL_SPECIFIC="from-session-vars-new"/export SHELL_SPECIFIC="same-at-login"/' \
      -e '/export FUTURE_GENERIC="from-future-generation"/d' \
      -e '/export FUTURE_INTEGER="9"/d' \
      "$TESTED/$sessionVarsFile" > "$loginSessionVars"
    testBashrc=$TMPDIR/test-bashrc
    testProfile=$TMPDIR/test-profile
    rewrite .bashrc "$testBashrc" "$TESTED/$sessionVarsFile"
    rewrite .profile "$testProfile" "$loginSessionVars"

    testHome=$TMPDIR/test-home
    mkdir -p "$testHome"
    cp "$TESTED/home-files/.bash_profile" "$testHome/.bash_profile"
    cp "$testProfile" "$testHome/.profile"
    cp "$testBashrc" "$testHome/.bashrc"

    childScript=$TMPDIR/bash-session-child.sh
    ${realPkgs.coreutils}/bin/cat > "$childScript" <<'EOF'
      case "$-" in *i*) ;; *) echo "child is not interactive: $-"; exit 1 ;; esac
      ! shopt -q login_shell || { echo "child is unexpectedly a login shell"; exit 1; }
      [ "''${REFRESHED}" = current ] || { echo "unowned generic refresh failed: ''${REFRESHED}"; exit 1; }
      [ "''${NULL_BASH_VALUE}" = current ] || { echo "null Bash value blocked generic refresh: ''${NULL_BASH_VALUE}"; exit 1; }
      [ "''${SHELL_SPECIFIC}" = same-at-login ] || { echo "Bash-owned value changed: ''${SHELL_SPECIFIC}"; exit 1; }
      [ "''${BASH_SEARCH}" = /bash/search ] || { echo "Bash-owned search value changed: ''${BASH_SEARCH}"; exit 1; }
      [ "''${FROM_PROFILE_EXTRA}" = from-profile-extra ] || { echo "profileExtra changed value lost: ''${FROM_PROFILE_EXTRA}"; exit 1; }
      [ "''${FUTURE_GENERIC}" = from-profile-extra ] || { echo "profileExtra value added before the generic key was introduced was lost: ''${FUTURE_GENERIC}"; exit 1; }
      [ "''${FUTURE_INTEGER}" = 7 ] || { echo "attributed profileExtra export was lost: ''${FUTURE_INTEGER}"; exit 1; }
      [ "''${PROFILE_CHANGED}" = changed-by-profile ] || { echo "profileExtra override lost: ''${PROFILE_CHANGED}"; exit 1; }
      [ ! -v PROFILE_UNSET ] || { echo "profileExtra unset value restored incorrectly"; exit 1; }
      [ ! -v PROFILE_SEARCH ] || { echo "profileExtra unset search value restored incorrectly"; exit 1; }
      [ -n "''${__HM_BASH_SESSION_VARS_MANIFEST}" ] || {
        echo "manifest was not inherited"
        exit 1
      }
      for owned in FUTURE_GENERIC FUTURE_INTEGER; do
        case " ''${__HM_BASH_SESSION_VARS_MANIFEST} " in
          *" $owned "*) ;;
          *) echo "new generic key was not claimed: $owned"; exit 1 ;;
        esac
      done
      export REFRESHED=manual
      manifestAfterAutomatic="''${__HM_BASH_SESSION_VARS_MANIFEST}"
      . "$HOME/.bashrc"
      [ "''${REFRESHED}" = current ] || { echo "manual non-owned override survived: ''${REFRESHED}"; exit 1; }
      [ "''${__HM_BASH_SESSION_VARS_MANIFEST}" = "$manifestAfterAutomatic" ] || {
        echo "manifest grew after repeated .bashrc sourcing"
        exit 1
      }
      case ":''${PATH}:" in *:/hm/bin:*) ;; *) echo "sessionPath missing: ''${PATH}"; exit 1 ;; esac
    EOF

    # 1. A real login parent must preserve profileExtra and declaratively-owned
    #    values while its interactive non-login child refreshes generic values.
    HOME="$testHome" TERM="dumb" TERMINFO_DIRS="" PATH="/usr/bin" CHILD_SCRIPT="$childScript" \
      "$BASH" --noprofile --norc -lic '
        . "$HOME/.profile"
        for owned in SHELL_SPECIFIC BASH_SEARCH FROM_PROFILE_EXTRA FUTURE_GENERIC FUTURE_INTEGER PROFILE_CHANGED PROFILE_UNSET PROFILE_SEARCH; do
          case " ''${__HM_BASH_SESSION_VARS_MANIFEST-} " in
            *" $owned "*) ;;
            *) echo "manifest omitted $owned: ''${__HM_BASH_SESSION_VARS_MANIFEST-}"; exit 1 ;;
          esac
        done
        case " ''${__HM_BASH_SESSION_VARS_MANIFEST-} " in
          *" REFRESHED "*)
            echo "manifest claimed unowned key: ''${__HM_BASH_SESSION_VARS_MANIFEST-}"
            exit 1
            ;;
        esac
        case " ''${__HM_BASH_SESSION_VARS_MANIFEST-} " in
          *" NULL_BASH_VALUE "*)
            echo "null Bash value claimed ownership: ''${__HM_BASH_SESSION_VARS_MANIFEST-}"
            exit 1
            ;;
        esac
        [ "''${SHELL_SPECIFIC}" = same-at-login ] || exit 1
        [ "''${BASH_SEARCH}" = /bash/search ] || exit 1
        [ "''${FROM_PROFILE_EXTRA}" = from-profile-extra ] || exit 1
        [ "''${FUTURE_GENERIC}" = from-profile-extra ] || exit 1
        [ "''${FUTURE_INTEGER}" = 7 ] || exit 1
        [ "''${PROFILE_CHANGED}" = changed-by-profile ] || exit 1
        [ ! -v PROFILE_UNSET ] || exit 1
        [ ! -v PROFILE_SEARCH ] || exit 1
        # Model a login shell started by a generation before these generic
        # variables existed.
        __HM_BASH_SESSION_VARS_MANIFEST="''${__HM_BASH_SESSION_VARS_MANIFEST// FUTURE_GENERIC/}"
        __HM_BASH_SESSION_VARS_MANIFEST="''${__HM_BASH_SESSION_VARS_MANIFEST// FUTURE_INTEGER/}"
        __HM_BASH_SESSION_VARS_KNOWN="''${__HM_BASH_SESSION_VARS_KNOWN// FUTURE_GENERIC/}"
        __HM_BASH_SESSION_VARS_KNOWN="''${__HM_BASH_SESSION_VARS_KNOWN// FUTURE_INTEGER/}"
        export __HM_BASH_SESSION_VARS_MANIFEST __HM_BASH_SESSION_VARS_KNOWN
        "$BASH" --noprofile --norc -ic ". \"$HOME/.bashrc\"; . \"$CHILD_SCRIPT\""
      ' || fail "login parent/interactive child session refresh failed"

    # 2. A child created from a pre-manifest generation cannot distinguish
    #    generic values from profileExtra overrides. Preserve existing
    #    generated values conservatively, while still applying unset values
    #    and current declarative Bash ownership.
    env -u __HM_BASH_SESSION_VARS_MANIFEST -u __HM_BASH_SESSION_VARS_KNOWN \
      HOME="$testHome" TERM="dumb" TERMINFO_DIRS="" PATH="/usr/bin" \
      REFRESHED="stale" SHELL_SPECIFIC="same-at-login" BASH_SEARCH="/bash/search" \
      "$BASH" --noprofile --norc -ic ". \"$testBashrc\"
        [ \"\$REFRESHED\" = stale ] || exit 1
        [ \"\$NULL_BASH_VALUE\" = current ] || exit 1
        [ \"\$SHELL_SPECIFIC\" = same-at-login ] || exit 1
        [ \"\$BASH_SEARCH\" = /bash/search ] || exit 1" \
      || fail "pre-manifest Bash environment was not migrated conservatively"

    # 3. Bash before 4.2 cannot run the ownership bookkeeping. Simulate that
    #    version branch and preserve the inherited login environment instead.
    legacyBashrc=$TMPDIR/legacy-bashrc
    sed 's/case "''${BASH_VERSION-}" in/case "3.2" in/' "$testBashrc" > "$legacyBashrc"
    env -u __HM_BASH_SESSION_VARS_MANIFEST -u __HM_BASH_SESSION_VARS_KNOWN \
      HOME="$testHome" TERM="dumb" TERMINFO_DIRS="" PATH="/usr/bin" \
      REFRESHED="stale" OVERRIDDEN="from-session-vars" \
      "$BASH" --noprofile --norc -ic ". \"$legacyBashrc\"
        [ \"\$REFRESHED\" = stale ] || exit 1
        [ \"\$OVERRIDDEN\" = from-bashrc ] || exit 1" \
      || fail "legacy Bash fallback did not preserve the login environment"

    # 4. Non-interactive shell reached through ssh/scp/rsync. Bash is built
    #    with SSH_SOURCE_BASHRC, so it reads .bashrc here; the once-per-session
    #    section must not run and stdout must stay clean.
    sshOut=$(HOME="$TESTED/home-files" TERM="dumb" TERMINFO_DIRS="" \
      SSH_CLIENT="1 2 3" PATH="/usr/bin" \
      "$BASH" --noprofile -c "printf 'EXTRA_MARKER=%s' \"\''${EXTRA_MARKER-unset}\"" 2>&1)
    [ "$sshOut" = "EXTRA_MARKER=unset" ] \
      || fail "ssh-style non-interactive Bash sourced session variables: '$sshOut'"

    # 5. Re-sourcing must not accumulate PATH entries.
    HOME="$TESTED/home-files" TERM="dumb" TERMINFO_DIRS="" PATH="/usr/bin" \
      __HM_BASH_SESSION_VARS_MANIFEST="" __HM_BASH_SESSION_VARS_KNOWN=" PATH" \
      "$BASH" --noprofile --norc -ic ". \"$testBashrc\"
        . \"$testBashrc\"
        [ \"\$PATH\" = /hm/bin:/usr/bin ] || { echo \"PATH after two sources: \$PATH\"; exit 1; }" \
      || fail "repeated .bashrc sourcing changed PATH"

    # 6. POSIX shell (dash) must source .profile without errors. Bash-only
    #    ownership bookkeeping must be skipped, but generic session variables
    #    and profileExtra must still apply.
    dashProfile=$TMPDIR/dash-profile
    rewrite .profile "$dashProfile" "$TESTED/$sessionVarsFile"
    dashErr=$TMPDIR/dash-stderr
    dashOut=$(HOME="$testHome" TERM="dumb" TERMINFO_DIRS="" PATH="/usr/bin" \
      ${realPkgs.dash}/bin/dash -c '. "$1" && printf "REFRESHED=%s SHELL_SPECIFIC=%s FROM_PROFILE_EXTRA=%s MANIFEST=<%s>" \
        "$REFRESHED" "$SHELL_SPECIFIC" "$FROM_PROFILE_EXTRA" "''${__HM_BASH_SESSION_VARS_MANIFEST-}"' \
      dash "$dashProfile" 2>"$dashErr") \
      || fail "dash failed to source .profile: $(cat "$dashErr")"
    [ ! -s "$dashErr" ] \
      || fail "dash emitted stderr sourcing .profile: $(cat "$dashErr")"
    case "$dashOut" in
      *"REFRESHED=current"*) ;;
      *) fail "dash: generic REFRESHED not applied: $dashOut" ;;
    esac
    case "$dashOut" in
      *"SHELL_SPECIFIC=same-at-login"*) ;;
      *) fail "dash: programs.bash.sessionVariables not applied: $dashOut" ;;
    esac
    case "$dashOut" in
      *"FROM_PROFILE_EXTRA=from-profile-extra"*) ;;
      *) fail "dash: profileExtra not applied: $dashOut" ;;
    esac
    case "$dashOut" in
      *"MANIFEST=<>"*) ;;
      *"MANIFEST=<"*) fail "dash: __HM_BASH_SESSION_VARS_MANIFEST should be empty under POSIX shell: $dashOut" ;;
      *) fail "dash: unexpected manifest output: $dashOut" ;;
    esac
  '';
}
