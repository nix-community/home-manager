{ lib, ... }:
{
  options.neverest = {
    enable = lib.mkEnableOption "synchronization using Neverest";

    poolSize = lib.mkOption {
      type = lib.types.nullOr lib.types.ints.positive;
      default = null;
      example = 4;
      description = ''
        Maximum concurrent IMAP connections for this account.
      '';
    };

    mailboxFilters = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.submodule {
          options = {
            include = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              example = [
                "INBOX"
                "Sent"
              ];
              description = "Mailboxes to include. Mutually exclusive with {option}`exclude`.";
            };
            exclude = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              example = [ "Spam" ];
              description = "Mailboxes to exclude. Mutually exclusive with {option}`include`.";
            };
          };
        }
      );
      default = null;
      description = ''
        Restrict which mailboxes neverest synchronizes.
        Set {option}`include` or {option}`exclude`, not both.
        When null, all mailboxes are synchronized.
      '';
    };

    protectServer = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Set `right.folder.permissions.create/delete` and
        `right.message.permissions.create/delete` to `false`, preventing
        neverest from modifying mailboxes or messages on the remote
        IMAP server. Useful when the server is the authoritative source.
      '';
    };

    extraConfig = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      example = {
        right.backend.watch.timeout = 1800;
      };
      description = ''
        Extra configuration merged into this account's TOML section.
        Keys must follow neverest's actual account schema (`default`,
        `folder`, `envelope`, `left`, `right` — see the neverest and
        email-lib source for the full shape); the top-level config and
        account structs use `deny_unknown_fields`, so unrecognized keys
        will make neverest fail to parse the config entirely.
      '';
    };
  };
}
