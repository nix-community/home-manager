{ config, lib, pkgs, ... }:

with lib;
with import ./lib/mail.nix { inherit lib config; };

let

  cfg = config.mail;

  dag = config.lib.dag;

  fileType = (import ./lib/file-type.nix {
    inherit (config.home) homeDirectory;
    inherit lib pkgs;
  }).fileType;

    mailAccount = types.submodule {
      options = rec {

        # should be unque across mailAccounts => use it as key ?
        # but it is used
        name = mkOption {
          type = types.str;
          description = "Just to identify the account";
        };

        userName = mkOption {
          type = types.str;
          description = "The foreground color.";
        };

        realname = mkOption {
          type = types.str;
          description = "Name displayed when sending mails.";
        };

        signature = mkOption {
          type = types.str;
          default = "default signature";
          example = "luke@tatooine.com";
          description = "Your signature";
        };

        address = mkOption {
          type = types.str;
          example = "luke@tatooine.com";
          description = "Your mail address";
        };

        # pgp key
        # key = mkOption {
        #   type = types.path;
        #   example = null;
        #   description = "Your PGP key/file";
        # };

        imapHost = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "imap.server.be";
          description = "IMAP host to receive mails from";
        };

        sendHost = mkOption {
          type = types.str;
          example = "luke@tatooine.com";
          description = "MSMTP host to use to send mails";
        };

        # might be hard to abstract
        # getPassCommand = mkOption {
        #   default = null;
        #   type = types.nullOr types.str;
        #   description = "The bold color, null to use same as foreground.";
        # };

        # depend if notmuch is enabled or not
        postSyncHook = mkOption {
          type = types.nullOr types.path;
          # ${name}
          default = null;
          # default = "${cfg.maildir}/${name}";
          description = "Where to store mail for this account";
        };
        
        # MtaSubmoduleMsmtp = types.submodule {

        #   offlineSendMethod = mkOption {
        #     # https://wiki.archlinux.org/index.php/Msmtp#Using_msmtp_offline
        #     # see for a list of methodds 
        #     # https://github.com/pazz/alot/wiki/Tips,-Tricks-and-other-cool-Hacks
        #     type = types.enum [ "none" "native" ];
        #     default = "native";
        #     description = "Extra configuration lines to add to .msmtprc.";
        #   };

        #   sendCommand = mkOption {
        #     # https://wiki.archlinux.org/index.php/Msmtp#Using_msmtp_offline
        #     # see for a list of methodds 
        #     # https://github.com/pazz/alot/wiki/Tips,-Tricks-and-other-cool-Hacks
        #     # type = types.str;
        #     default = sendMsmtpCommand ;
        #     description = "Extra configuration lines to add to .msmtprc.";
        #   };

        #   extraConfig = mkOption {
        #     type = types.lines;
        #     default = "";
        #     description = "Extra configuration lines to add to .msmtprc.";
        #   };
        # };
        # types.submodule {

        # submodule
        # types.attrs;
        # mta = mkOption {
        #   type = types.enum [ MtaSubmoduleMsmtp ];
        #   # path
        #   # type = types.str;
        #   # ${name}
        #   default = MtaSubmoduleMsmtp;
        #   description = "Where to store mail for this account";
        # };

        # keep it for now ?
        store = mkOption {
          # path
          type = types.nullOr types.path;
          default = null;
          # default = "${cfg.maildir}/${name.value}";
          description = "Where to store mail for this account";
        };

      };
    };

in

{

  options.mail = rec {
    maildir = mkOption {
      type = types.path;
      # fileType "<varname>mail.maildir</varname>" cfg.configHome + "maildir";
      default = config.home.homeDirectory + "/maildir";
      description = ''
        Attribute set of files to link into the user's XDG
        configuration home.
      '';
    };

    # enable = mkEnableOption "management of XDG base directories";

    accounts = mkOption {
      type = types.listOf mailAccount;
      # type = types.attrsOf mailAccount;
      description = "List your email accounts.";
    };


    generateAliases = mkOption {
      default = true;
      type = types.bool;
      # todo let it a function ?
      description = ''
        Generate one shell alias per (program/account). For instance, if alot is enabled and an account is defined with name gmail, then it will generate alot-gmail
      '';

      # generateDesktopFiles = mkOption {
      #   default = true;
      #   type = types.bool;
      #   description = ''
      #     Generate .desktop files if MUA has already a desktop.
      #   '';
      # };
    };
  };

  config = mkMerge [
    {
    # mkIf cfg.enable {
      home.sessionVariables = {
        MAILDIR = cfg.maildir;
      };

      # TODO might neeed to generate several aliases depending on mua

      programs.bash.shellAliases = 
      let 
        genAliasesList = mailAccounts:
          map  (account: { name = "alot-${account.name}"; value = "${pkgs.alot} -n ${config.xdg.configHome}/notmuch/notmuch_${account.name}"; }) mailAccounts ;
        listToAttrs = list: (foldr // {} list);
          # builtins.listToAttrs
        in
        {
          alot_test="echo 'test successful'";
        }
        // (lib.optionalAttrs cfg.generateAliases (
          builtins.listToAttrs (genAliasesList cfg.accounts) 
        )
      );

      # todo check mta/mua creation process
      home.activation.createMailStores = dag.entryBefore [ "linkGeneration" ] (
        concatStringsSep ";" (map (account: "mkdir ${getStore account}") cfg.accounts)
      );
      # need to create the maildirs !
    }
    # )
  ];

}

