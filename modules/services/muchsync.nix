{ config, lib, pkgs, ... }:

with lib;

# Documentation was partially copied from the muchsync manual.
# See http://www.muchsync.org/muchsync.html

let
  cfg = config.services.muchsync;
  syncOptions = {
    options = {
      frequency = mkOption {
        type = types.str;
        default = "*:0/5";
        description = ''
          How often to run <command>muchsync</command>. This
          value is passed to the systemd timer configuration as the
          <literal>OnCalendar</literal> option. See
          <citerefentry>
            <refentrytitle>systemd.time</refentrytitle>
            <manvolnum>7</manvolnum>
          </citerefentry>
          for more information about the format.
        '';
      };

      sshCommand = mkOption {
        type = types.str;
        default = "${pkgs.openssh}/bin/ssh -CTaxq";
        defaultText = "ssh -CTaxq";
        description = ''
          Specifies a command line to pass to <command>/bin/sh</command>
          to execute a command on another machine.
          </para><para>
          Note that because this string is passed to the shell,
          special characters including spaces may need to be escaped.
        '';
      };

      upload = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to propagate local changes to the remote.
        '';
      };

      local = {
        checkForModifiedFiles = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Check for locally modified files.
            Without this option, muchsync assumes that files in a maildir are
            never edited.
            </para><para>
            <option>checkForModifiedFiles</option> disables certain
            optimizations so as to make muchsync at least check the timestamp on
            every file, which will detect modified files at the cost of a longer
            startup time.
            </para><para>
            This option is useful if your software regularly modifies the
            contents of mail files (e.g., because you are running offlineimap
            with "synclabels = yes").
          '';
        };

        importNew = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Whether to begin the synchronisation by running
            <command>notmuch new</command> locally.
          '';
        };
      };

      remote = {
        host = mkOption {
          type = types.str;
          description = ''
            Remote SSH host to synchronize with.
          '';
        };

        muchsyncPath = mkOption {
          type = types.str;
          default = "";
          defaultText = "$PATH/muchsync";
          description = ''
            Specifies the path to muchsync on the server.
            Ordinarily, muchsync should be in the default PATH on the server
            so this option is not required.
            However, this option is useful if you have to install muchsync in
            a non-standard place or wish to test development versions of the
            code.
          '';
        };

        checkForModifiedFiles = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Check for modified files on the remote side.
            Without this option, muchsync assumes that files in a maildir are
            never edited.
            </para><para>
            <option>checkForModifiedFiles</option> disables certain
            optimizations so as to make muchsync at least check the timestamp on
            every file, which will detect modified files at the cost of a longer
            startup time.
            </para><para>
            This option is useful if your software regularly modifies the
            contents of mail files (e.g., because you are running offlineimap
            with "synclabels = yes").
          '';
        };

        importNew = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Whether to begin the synchronisation by running
            <command>notmuch new</command> on the remote side.
          '';
        };
      };
    };
  };

in {
  meta.maintainers = with maintainers; [ pacien ];

  options.services.muchsync = {
    remotes = mkOption {
      type = with types; attrsOf (submodule syncOptions);
      default = { };
      example = literalExpression ''
        {
          server = {
            frequency = "*:0/10";
            remote.host = "server.tld";
          };
        }
      '';
      description = ''
        Muchsync remotes to synchronise with.
      '';
    };
  };

  config = let
    mapRemotes = gen:
      with attrsets;
      mapAttrs'
      (name: remoteCfg: nameValuePair "muchsync-${name}" (gen name remoteCfg))
      cfg.remotes;
  in mkIf (cfg.remotes != { }) {
    assertions = [
      (hm.assertions.assertPlatform "services.muchsync" pkgs platforms.linux)

      {
        assertion = config.programs.notmuch.enable;
        message = ''
          The muchsync module requires 'programs.notmuch.enable = true'.
        '';
      }
    ];

    systemd.user.services = mapRemotes (name: remoteCfg: {
      Unit = { Description = "muchsync sync service (${name})"; };
      Service = {
        CPUSchedulingPolicy = "idle";
        IOSchedulingClass = "idle";
        Environment = [
          ''"PATH=${pkgs.notmuch}/bin"''
          ''"NOTMUCH_CONFIG=${config.home.sessionVariables.NOTMUCH_CONFIG}"''
          ''"NMBGIT=${config.home.sessionVariables.NMBGIT}"''
        ];
        ExecStart = concatStringsSep " " ([ "${pkgs.muchsync}/bin/muchsync" ]
          ++ [ "-s ${escapeShellArg remoteCfg.sshCommand}" ]
          ++ optional (!remoteCfg.upload) "--noup"

          # local configuration
          ++ optional remoteCfg.local.checkForModifiedFiles "-F"
          ++ optional (!remoteCfg.local.importNew) "--nonew"

          # remote configuration
          ++ [ (escapeShellArg remoteCfg.remote.host) ]
          ++ optional (remoteCfg.remote.muchsyncPath != "")
          "-r ${escapeShellArg remoteCfg.remote.muchsyncPath}"
          ++ optional remoteCfg.remote.checkForModifiedFiles "-F"
          ++ optional (!remoteCfg.remote.importNew) "--nonew");
      };
    });

    systemd.user.timers = mapRemotes (name: remoteCfg: {
      Unit = { Description = "muchsync periodic sync (${name})"; };
      Timer = {
        Unit = "muchsync-${name}.service";
        OnCalendar = remoteCfg.frequency;
        Persistent = true;
      };
      Install = { WantedBy = [ "timers.target" ]; };
    });
  };
}
