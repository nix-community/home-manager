{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkOption
    types
    mkIf
    ;

  enabledAccounts = lib.attrsets.filterAttrs (
    name: value: value.meli.enable or false
  ) config.accounts.email.accounts;

  meliAccounts = (lib.attrsets.mapAttrs (name: value: (mkMeliAccounts name value)) enabledAccounts);

  mkMeliAccounts = (
    name: account: {
      root_mailbox = "${config.accounts.email.maildirBasePath}/${account.maildir.path}";
      format = "Maildir";
      identity = "${account.address}";
      display_name = "${account.realName}";
      subscribed_mailboxes = account.meli.mailboxes;
      send_mail = mkSmtp account;
      mailboxes = account.meli.mailboxAliases;
    }
  );

  mkSmtp = account: {
    hostname = account.smtp.host;
    port = account.smtp.port;
    auth = {
      type = "auto";
      username = account.userName;
      password = {
        type = "command_eval";
        value = lib.strings.concatStringsSep " " account.passwordCommand;
      };
    };
    security = {
      type =
        if account.smtp.tls.enable or false then
          if account.smtp.tls.useStartTls or false then "starttls" else "tls"
        else
          "none";
      danger_accept_invalid_certs = false;
    };
    extensions = {
      PIPELINING = true;
      CHUNKING = true;
      PRDR = true;
      DSN_NOTIFY = "FAILURE";
    };
  };

in
{
  meta.maintainers = with lib.hm.maintainers; [ munsman ];

  options = {
    programs.meli = {
      enable = mkEnableOption "meli email client";

      package = mkOption {
        type = types.package;
        default = pkgs.meli;
        description = "meli package to use";
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Additional lines to add to meli config.toml";
      };
      settings = mkOption {
        type = types.submodule {
          options = {
            shortcuts = mkOption {
              type = types.submodule {
                options = {
                  general = mkOption {
                    type = types.attrsOf types.str;
                    default = { };
                    description = "general shortcut configuration";
                    example = {
                      scroll_up = "e";
                      scroll_down = "n";
                      next_page = "C-d";
                    };
                  };
                  composing = mkOption {
                    type = types.attrsOf types.str;
                    default = { };
                    description = "composing shortcut configuration";
                    example = {
                      edit = "m";
                      scroll_up = "e";
                      scroll_down = "n";
                    };
                  };
                  contact-list = mkOption {
                    type = types.attrsOf types.str;
                    default = { };
                    description = "contact-list shortcut configuration";
                    example = {
                      create_contact = "c";
                      edit_contact = "m";
                    };
                  };
                  listing = mkOption {
                    type = types.attrsOf types.str;
                    default = { };
                    description = "general shortcut configuration";
                    example = {
                      new_mail = "t";
                      set_seen = "s";
                    };
                  };
                  pager = mkOption {
                    type = types.attrsOf types.str;
                    default = "";
                    description = "general shortcut configuration";
                    example = {
                      scroll_up = "e";
                      scroll_down = "n";
                    };
                  };
                };
              };
              default = { };
              description = "Shortcut Settings";
            };
          };
        };
        default = { };
        description = "Meli Configuration";
      };
    };
    accounts.email.accounts = mkOption {
      type = types.attrsOf (
        types.submodule (
          { config, ... }:
          {
            options.meli = {
              enable = mkEnableOption "the meli mail client for this account";
              mailboxes = mkOption {
                type = with types; listOf str;
                default = (
                  with config.folders;
                  [
                    inbox
                    sent
                    trash
                    drafts
                  ]
                );
                example = [
                  "INBOX"
                  "Sent"
                  "Trash"
                  "Drafts"
                ];
                description = "Mailboxes to show in meli";
              };
              mailboxAliases = mkOption {
                type = with types; attrsOf attrs;
                default = { };
                example = {
                  "INBOX" = {
                    alias = "📥 Inbox";
                  };
                  "Sent" = {
                    alias = "📤 Sent";
                  };
                };
                description = "Folder display name";
              };
            };
          }
        )
      );
    };
  };

  config = mkIf config.programs.meli.enable {
    home.packages = [ config.programs.meli.package ];

    assertions = lib.concatLists (
      lib.attrsets.mapAttrsToList (
        name: account:
        lib.optional (account.meli.enable or false) {
          assertion = account ? smtp;
          message = "The email account '${name}' must have an 'smtp' attribute defined when enabling meli.";
        }
      ) config.accounts.email.accounts
    );

    # Generate meli configuration from email accounts
    xdg.configFile."meli/config.toml".source = (pkgs.formats.toml { }).generate "meli-config" (
      # Account Settings
      {
        accounts = meliAccounts;
      }
      //
        # Application Settings
        {
          shortcuts = {
            general = config.programs.meli.settings.shortcuts.general;
            composing = config.programs.meli.settings.shortcuts.composing;
            contact-list = config.programs.meli.settings.shortcuts.contact-list;
            listing = config.programs.meli.settings.shortcuts.listing;
            pager = config.programs.meli.settings.shortcuts.pager;
          };
        }
    );
  };
}
