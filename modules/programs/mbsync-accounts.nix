{ config, lib, ... }:

with lib;

let

  extraConfigType = with lib.types; attrsOf (either (either str int) bool);

  perAccountGroups = { name, config, ... }: {
    options = {
      groupName = mkOption {
        type = types.str;
        default = name;
        description = ''
          The name of this group for this account. These names are different than
          some others, because they will hide channel names that are the same.
        '';
      };

      channels = mkOption {
        type = types.listOf (types.submodule groupChannel);
        default = { };
        description = ''
          List of channels that should be grouped together into this group. When
          performing a synchronization, the groups are synchronized, rather than
          the individual channels.
          </para><para>
          Using these channels and then grouping them together allows for you to
          define the maildir hierarchy as you see fit.
        '';
      };
    };
  };

  # Options for configuring channel(s) that will be composed together into a group.
  groupChannel = { config, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        default = "DEFAULT";
        description = ''
          The unique name for THIS channel in THIS group. The group will refer to
          this channel by this name.
          </para><para>
          In addition, you can manually sync just this channel by specifying this
          name to mbsync on the command line.
        '';
      };

      masterPattern = mkOption {
        type = types.str;
        default = "";
        description = ''
          Regular expression pattern for which mailboxes on the remote mail server
          to sync.
          </para><para>
          If this is left as the default, then mbsync will default to the pattern
          <literal>INBOX</literal>.
        '';
      };

      slavePattern = mkOption {
        type = types.str;
        default = "";
        description = ''
          Name for where mail coming from the master mail server will end up
          locally. The mailbox specified by the master's pattern will be placed
          in this directory.
          </para><para>
          If this is left as the default, then mbsync will default to the pattern
          <literal>INBOX</literal>.
        '';
      };
    };
  };

in {
  options.mbsync = {
    enable = mkEnableOption "synchronization using mbsync";

    flatten = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = ".";
      description = ''
        If set, flattens the hierarchy within the maildir by
        substituting the canonical hierarchy delimiter
        <literal>/</literal> with this value.
      '';
    };

    create = mkOption {
      type = types.enum [ "none" "maildir" "imap" "both" ];
      default = "none";
      example = "maildir";
      description = ''
        Automatically create missing mailboxes within the
        given mail store.
      '';
    };

    remove = mkOption {
      type = types.enum [ "none" "maildir" "imap" "both" ];
      default = "none";
      example = "imap";
      description = ''
        Propagate mailbox deletions to the given mail store.
      '';
    };

    expunge = mkOption {
      type = types.enum [ "none" "maildir" "imap" "both" ];
      default = "none";
      example = "both";
      description = ''
        Permanently remove messages marked for deletion from
        the given mail store.
      '';
    };

    patterns = mkOption {
      type = types.listOf types.str;
      default = [ "*" ];
      description = ''
        Pattern of mailboxes to synchronize.
      '';
    };

    groups = mkOption {
      type = types.attrsOf (types.submodule perAccountGroups);
      default = { };
      description = ''
        Some email providers (Gmail) have a different directory hierarchy for
        synchronized email messages. Namely, when using mbsync without specifying
        a set of channels into a group, all synchronized directories end up beneath
        the <literal>[Gmail]/</literal> directory.
        </para><para>
        This option allows you to specify a group, and subsequently channels that
        will allow you to sync your mail into an arbitrary hierarchy.
      '';
    };

    extraConfig.channel = mkOption {
      type = extraConfigType;
      default = { };
      example = literalExample ''
        {
          MaxMessages = 10000;
          MaxSize = "1m";
        };
      '';
      description = ''
        Per channel extra configuration.
      '';
    };

    extraConfig.local = mkOption {
      type = extraConfigType;
      default = { };
      description = ''
        Local store extra configuration.
      '';
    };

    extraConfig.remote = mkOption {
      type = extraConfigType;
      default = { };
      description = ''
        Remote store extra configuration.
      '';
    };

    extraConfig.account = mkOption {
      type = extraConfigType;
      default = { };
      example = literalExample ''
        {
          PipelineDepth = 10;
          Timeout = 60;
        };
      '';
      description = ''
        Account section extra configuration.
      '';
    };
  };
}
