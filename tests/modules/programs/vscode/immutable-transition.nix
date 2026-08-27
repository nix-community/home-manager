package:

{
  config,
  lib,
  pkgs,
  ...
}:

let
  userPath =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/Code/User"
    else
      ".config/Code/User";
  settingsPath = "${userPath}/settings.json";
  disabledSettingsPath = "${userPath}/profiles/disabled/settings.json";
  activationTemplate = pkgs.writeShellScript "activation" ''
    set -eu
    set -o pipefail
    PATH="$(dirname "$BASH"):${
      lib.makeBinPath [
        pkgs.coreutils
        pkgs.diffutils
        pkgs.findutils
      ]
    }:$PATH"
    ${config.lib.bash.initHomeManagerLib}

    newGenPath="$TESTED"
    ${config.home.activation.checkLinkTargets.data}
    ${config.home.activation.vscodeImmutableUserSettings.data}
    ${config.home.activation.linkGeneration.data}
  '';
  sed = lib.getExe pkgs.gnused;
in
{
  programs.vscode = {
    enable = true;
    inherit package;
    mutableExtensionsDir = false;
    profiles.default = {
      mutableUserSettings = false;
      userSettings.transition = "immutable";
    };
    profiles.disabled = {
      mutableUserSettings = false;
      userSettings.transition = "immutable";
    };
  };

  home.homeDirectory = lib.mkForce "/@HOME@";
  home.file."${config.home.homeDirectory}/${disabledSettingsPath}".enable = false;

  nmt.script = ''
    set -eu
    set -o pipefail

    export TESTED
    generated_settings="$TESTED/home-files/${settingsPath}"
    assertPathNotExists "home-files/${disabledSettingsPath}"

    identical_home="$TMPDIR/identical-home"
    mkdir -p "$identical_home/${userPath}/profiles/disabled"
    cp --dereference "$generated_settings" "$identical_home/${settingsPath}"
    cp --dereference "$generated_settings" "$identical_home/${disabledSettingsPath}"
    ${sed} "s|/@HOME@|$identical_home|g" ${activationTemplate} > $TMPDIR/activate-identical
    chmod +x $TMPDIR/activate-identical

    HOME="$identical_home" \
      HOME_MANAGER_BACKUP_COMMAND= \
      HOME_MANAGER_BACKUP_EXT= \
      HOME_MANAGER_BACKUP_OVERWRITE= \
      $TMPDIR/activate-identical

    test -L "$identical_home/${settingsPath}"
    test "$(readlink -e "$identical_home/${settingsPath}")" = "$(readlink -e "$generated_settings")"
    if [[ ! -f "$identical_home/${disabledSettingsPath}" ]]; then
      echo "Activation removed disabled settings" >&2
      exit 1
    fi
    test ! -L "$identical_home/${disabledSettingsPath}"
    cmp "$generated_settings" "$identical_home/${disabledSettingsPath}"

    differing_home="$TMPDIR/differing-home"
    mkdir -p "$differing_home/${userPath}"
    printf '{"user": "newer"}\n' > "$differing_home/${settingsPath}"
    ${sed} "s|/@HOME@|$differing_home|g" ${activationTemplate} > $TMPDIR/activate-differing
    chmod +x $TMPDIR/activate-differing

    if HOME="$differing_home" \
      HOME_MANAGER_BACKUP_COMMAND= \
      HOME_MANAGER_BACKUP_EXT= \
      HOME_MANAGER_BACKUP_OVERWRITE= \
      $TMPDIR/activate-differing > $TMPDIR/differing-output 2>&1; then
      echo "Activation unexpectedly replaced differing mutable settings" >&2
      exit 1
    fi

    grep -F "Existing file '$differing_home/${settingsPath}' would be clobbered" \
      $TMPDIR/differing-output
    test ! -L "$differing_home/${settingsPath}"
    grep -Fx '{"user": "newer"}' "$differing_home/${settingsPath}"

    backup_home="$TMPDIR/backup-home"
    mkdir -p "$backup_home/${userPath}"
    printf '{"user": "backed-up"}\n' > "$backup_home/${settingsPath}"
    ${sed} "s|/@HOME@|$backup_home|g" ${activationTemplate} > $TMPDIR/activate-backup
    chmod +x $TMPDIR/activate-backup

    HOME="$backup_home" \
      HOME_MANAGER_BACKUP_COMMAND= \
      HOME_MANAGER_BACKUP_EXT=backup \
      HOME_MANAGER_BACKUP_OVERWRITE= \
      $TMPDIR/activate-backup

    test -L "$backup_home/${settingsPath}"
    test "$(readlink -e "$backup_home/${settingsPath}")" = "$(readlink -e "$generated_settings")"
    grep -Fx '{"user": "backed-up"}' "$backup_home/${settingsPath}.backup"
  '';
}
