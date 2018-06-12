{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.procmail;
  ruleModule = types.submodule ({config,...}: {
    options = {

      lock = mkOption {
        type = types.string;
        default = ":0:";
        description = "Locking rule.";
      };

      conditions = mkOption {
        type = types.listOf types.string;
        default = [];
        example = ["^From: .*@linkedin.com"];
        description = "Matching rules.";
      };

      target = mkOption {
        type = types.string;
        default = "";
        example = "mbox/";
        description = "Rule target. If you want a maildir, append a slash.";
      };
    };
  });

in

{
  options = {
    programs.procmail = {
      enable = mkEnableOption "the procmail mail processor";

      maildir = mkOption {
        type = types.string;
        default = "$HOME/Mail";
        description = "Base mail directory.";
      };

      finalDir = mkOption {
        type = types.string;
        default = "mbox/";
        description = "The final catch-all maildir.";
      };

      # Still thinking of proper syntax for this
      preConfig = mkOption {
        type = types.lines;
        default = "";
        example = ''
          # START spamassassin
          :0fw: spamassassin.lock
          * < 256000
          | ${pkgs.spamassassin}/bin/spamc
        '';
        description = "Configuration to add to the top after the header.";
      };

      rules = mkOption {
        type = types.listOf ruleModule;
        default = [];
        example = [
          {
            rules = ["^X-BeenThere: haskell-cafe@haskell.org"];
            target = "~/Mail/Lists/haskell-cafe/";
          }
        ];
        description = "List of procmail rules.";
      };

      postConfig = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Configuration to add as the last in the configuration file.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.file.".procmailrc".text =

    let
      preConfig = ''
        # START PRECONFIG
        ${cfg.preConfig}
        # END PRECONFIG
      '';

      formatRule = rule: ''
        ${rule.lock}
        ${concatStringsSep "\n" (map (c: "* ${c}") rule.conditions)}
        ${cfg.maildir}/${rule.target}
      '';

      rulesSection = ''
        # START RULES
        ${concatStringsSep "\n\n" (map formatRule cfg.rules)}
        # END RULES
      '';

      catchAll = ''
        # START CATCH-ALL RULE
        :0
        ${cfg.maildir}/${cfg.finalDir}
        # END CATCH-ALL RULE
      '';

      postConfig = ''
        # START POSTCONFIG
        ${cfg.postConfig}
        # END POSTCONFIG
      '';

    in

    ''
      LOGFILE=$HOME/logs/procmail.log

      ${preConfig}

      ${rulesSection}

      ${catchAll}

      ${postConfig}
    '';

    # The .forward file can't be a symlink, for now it needs to be created
    # manually
    # "|/home/user/.nix-profile/bin/procmail -t"
    home.packages = [ pkgs.procmail ];
  };
}
