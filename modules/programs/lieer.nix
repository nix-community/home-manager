{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.lieer;

  lieerAccounts =
    filter (a: a.lieer.enable) (attrValues config.accounts.email.accounts);

  nonGmailAccounts =
    map (a: a.name) (filter (a: a.flavor != "gmail.com") lieerAccounts);

  nonGmailConfigHelp =
    map (name: ''accounts.email.accounts.${name}.flavor = "gmail.com";'')
    nonGmailAccounts;

  missingNotmuchAccounts = map (a: a.name)
    (filter (a: !a.notmuch.enable && a.lieer.notmuchSetupWarning)
      lieerAccounts);

  notmuchConfigHelp =
    map (name: "accounts.email.accounts.${name}.notmuch.enable = true;")
    missingNotmuchAccounts;

  configFile = account: {
    name = "${account.maildir.absPath}/.gmailieer.json";
    value = {
      text = builtins.toJSON {
        inherit (account.lieer) timeout;
        account = account.address;
        replace_slash_with_dot = account.lieer.replaceSlashWithDot;
        drop_non_existing_label = account.lieer.dropNonExistingLabels;
        ignore_tags = account.lieer.ignoreTagsLocal;
        ignore_remote_labels = account.lieer.ignoreTagsRemote;
      } + "\n";
    };
  };

in {
  meta.maintainers = [ maintainers.tadfisher ];

  options = {
    programs.lieer.enable =
      mkEnableOption "lieer Gmail synchronization for notmuch";

    accounts.email.accounts = mkOption {
      type = with types; attrsOf (submodule (import ./lieer-accounts.nix));
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf (missingNotmuchAccounts != [ ]) {
      warnings = [''
        lieer is enabled for the following email accounts, but notmuch is not:

            ${concatStringsSep "\n    " missingNotmuchAccounts}

        Notmuch can be enabled with:

            ${concatStringsSep "\n    " notmuchConfigHelp}

        If you have configured notmuch outside of Home Manager, you can suppress this
        warning with:

            programs.lieer.notmuchSetupWarning = false;
      ''];
    })

    {
      assertions = [{
        assertion = nonGmailAccounts == [ ];
        message = ''
          lieer is enabled for non-Gmail accounts:

              ${concatStringsSep "\n    " nonGmailAccounts}

          If these accounts are actually Gmail accounts, you can
          fix this error with:

              ${concatStringsSep "\n    " nonGmailConfigHelp}
        '';
      }];

      home.packages = [ pkgs.gmailieer ];

      # Notmuch should ignore non-mail files created by lieer.
      programs.notmuch.new.ignore = [ "/.*[.](json|lock|bak)$/" ];

      home.file = listToAttrs (map configFile lieerAccounts);
    }
  ]);
}
