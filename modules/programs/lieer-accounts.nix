{ lib, ... }:

with lib;

{
  options.lieer = {
    enable = mkEnableOption "lieer Gmail synchronization for notmuch";

    timeout = mkOption {
      type = types.ints.unsigned;
      default = 0;
      description = ''
        HTTP timeout in seconds. 0 means forever or system timeout.
      '';
    };

    replaceSlashWithDot = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Replace '/' with '.' in Gmail labels.
      '';
    };

    dropNonExistingLabels = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Allow missing labels on the Gmail side to be dropped.
      '';
    };

    ignoreTagsLocal = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Set custom tags to ignore when syncing from local to
        remote (after translations).
      '';
    };

    ignoreTagsRemote = mkOption {
      type = types.listOf types.str;
      default = [
        "CATEGORY_FORUMS"
        "CATEGORY_PROMOTIONS"
        "CATEGORY_UPDATES"
        "CATEGORY_SOCIAL"
        "CATEGORY_PERSONAL"
      ];
      description = ''
        Set custom tags to ignore when syncing from remote to
        local (before translations).
      '';
    };

    notmuchSetupWarning = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Warn if Notmuch is not also enabled for this account.
        </para><para>
        This can safely be disabled if <command>notmuch init</command>
        has been used to configure this account outside of Home
        Manager.
      '';
    };
  };
}
