{ config, lib, pkgs, ... }:
let
  inherit (lib) literalExpression mkOption mkEnableOption mkPackageOption types;

  cfg = config.services.syncthing;

  settingsFormat = pkgs.formats.json { };
  cleanedConfig =
    lib.converge (lib.filterAttrsRecursive (_: v: v != null && v != { }))
    cfg.settings;

  isUnixGui = (builtins.substring 0 1 cfg.guiAddress) == "/";

  # syncthing's configuration directory (see https://docs.syncthing.net/users/config.html)
  syncthing_dir = if pkgs.stdenv.isDarwin then
    "$HOME/Library/Application Support/Syncthing"
  else
    "\${XDG_STATE_HOME:-$HOME/.local/state}/syncthing";

  # Syncthing supports serving the GUI over Unix sockets. If that happens, the
  # API is served over the Unix socket as well.  This function returns the correct
  # curl arguments for the address portion of the curl command for both network
  # and Unix socket addresses.
  curlAddressArgs = path:
    if isUnixGui
    # if cfg.guiAddress is a unix socket, tell curl explicitly about it
    # note that the dot in front of `${path}` is the hostname, which is
    # required.
    then
      "--unix-socket ${cfg.guiAddress} http://.${path}"
      # no adjustements are needed if cfg.guiAddress is a network address
    else
      "${cfg.guiAddress}${path}";

  devices = lib.mapAttrsToList (_: device: device // { deviceID = device.id; })
    cfg.settings.devices;

  folders = lib.mapAttrsToList (_: folder:
    folder // {
      devices = map (device:
        if builtins.isString device then {
          deviceId = cfg.settings.devices.${device}.id;
        } else
          device) folder.devices;
    }) (lib.filterAttrs (_: folder: folder.enable) cfg.settings.folders);

  jq = lib.getExe pkgs.jq;
  sleep = lib.getExe' pkgs.coreutils "sleep";
  printf = lib.getExe' pkgs.coreutils "printf";
  cat = lib.getExe' pkgs.coreutils "cat";
  curl = lib.getExe pkgs.curl;
  install = lib.getExe' pkgs.coreutils "install";
  mktemp = lib.getExe' pkgs.coreutils "mktemp";
  syncthing = lib.getExe cfg.package;

  copyKeys = pkgs.writers.writeBash "syncthing-copy-keys" ''
    ${install} -dm700 "${syncthing_dir}"
    ${lib.optionalString (cfg.cert != null) ''
      ${install} -Dm400 ${toString cfg.cert} "${syncthing_dir}/cert.pem"
    ''}
    ${lib.optionalString (cfg.key != null) ''
      ${install} -Dm400 ${toString cfg.key} "${syncthing_dir}/key.pem"
    ''}
  '';

  curlShellFunction = ''
    # systemd sets and creates RUNTIME_DIRECTORY on Linux
    # on Darwin, we create it manually via mktemp
    RUNTIME_DIRECTORY="''${RUNTIME_DIRECTORY:=$(${mktemp} -d)}"

    curl() {
        # get the api key by parsing the config.xml
        while
            ! ${pkgs.libxml2}/bin/xmllint \
                --xpath 'string(configuration/gui/apikey)' \
                "${syncthing_dir}/config.xml" \
                >"$RUNTIME_DIRECTORY/api_key"
        do ${sleep} 1; done
        (${printf} "X-API-Key: "; ${cat} "$RUNTIME_DIRECTORY/api_key") >"$RUNTIME_DIRECTORY/headers"
        ${curl} -sSLk -H "@$RUNTIME_DIRECTORY/headers" \
            --retry 1000 --retry-delay 1 --retry-all-errors \
            "$@"
    }
  '';

  updateConfig = pkgs.writers.writeBash "merge-syncthing-config" (''
    set -efu

    # be careful not to leak secrets in the filesystem or in process listings
    umask 0077

    ${curlShellFunction}
  '' +

    /* Syncthing's rest API for the folders and devices is almost identical.
       Hence we iterate them using lib.pipe and generate shell commands for both at
       the same time.
    */
    (lib.pipe {
      # The attributes below are the only ones that are different for devices /
      # folders.
      devs = {
        new_conf_IDs = map (v: v.id) devices;
        GET_IdAttrName = "deviceID";
        override = cfg.overrideDevices;
        conf = devices;
        baseAddress = curlAddressArgs "/rest/config/devices";
      };
      dirs = {
        new_conf_IDs = map (v: v.id) folders;
        GET_IdAttrName = "id";
        override = cfg.overrideFolders;
        conf = folders;
        baseAddress = curlAddressArgs "/rest/config/folders";
      };
    } [
      # Now for each of these attributes, write the curl commands that are
      # identical to both folders and devices.
      (lib.mapAttrs (conf_type: s:
        # We iterate the `conf` list now, and run a curl -X POST command for each, that
        # should update that device/folder only.
        lib.pipe s.conf [
          # Quoting https://docs.syncthing.net/rest/config.html:
          #
          # > PUT takes an array and POST a single object. In both cases if a
          # given folder/device already exists, it’s replaced, otherwise a new
          # one is added.
          #
          # What's not documented, is that using PUT will remove objects that
          # don't exist in the array given. That's why we use here `POST`, and
          # only if s.override == true then we DELETE the relevant folders
          # afterwards.
          (map (new_cfg: ''
            curl -d ${
              lib.escapeShellArg (builtins.toJSON new_cfg)
            } -X POST ${s.baseAddress}
          ''))
          (lib.concatStringsSep "\n")
        ]
        /* If we need to override devices/folders, we iterate all currently configured
           IDs, via another `curl -X GET`, and we delete all IDs that are not part of
           the Nix configured list of IDs
        */
        + lib.optionalString s.override ''
          stale_${conf_type}_ids="$(curl -X GET ${s.baseAddress} | ${jq} \
            --argjson new_ids ${
              lib.escapeShellArg (builtins.toJSON s.new_conf_IDs)
            } \
            --raw-output \
            '[.[].${s.GET_IdAttrName}] - $new_ids | .[]'
          )"
          for id in ''${stale_${conf_type}_ids}; do
            curl -X DELETE ${s.baseAddress}/$id
          done
        ''))
      builtins.attrValues
      (lib.concatStringsSep "\n")
    ]) +
    /* Now we update the other settings defined in cleanedConfig which are not
       "folders" or "devices".
    */
    (lib.pipe cleanedConfig [
      builtins.attrNames
      (lib.subtractLists [ "folders" "devices" ])
      (map (subOption: ''
        curl -X PUT -d ${
          lib.escapeShellArg (builtins.toJSON cleanedConfig.${subOption})
        } ${curlAddressArgs "/rest/config/${subOption}"}
      ''))
      (lib.concatStringsSep "\n")
    ]) + lib.optionalString (cfg.passwordFile != null) ''
      syncthing_password=$(${cat} ${cfg.passwordFile})
      curl -X PATCH -d '{"password": "'$syncthing_password'"}' ${
        curlAddressArgs "/rest/config/gui"
      }
    '' + ''
      # restart Syncthing if required
      if curl ${curlAddressArgs "/rest/config/restart-required"} |
         ${jq} -e .requiresRestart > /dev/null; then
          curl -X POST ${curlAddressArgs "/rest/system/restart"}
      fi
    '');

  defaultSyncthingArgs = [
    "${syncthing}"
    "-no-browser"
    "-no-restart"
    "-no-upgrade"
    "-gui-address=${if isUnixGui then "unix://" else ""}${cfg.guiAddress}"
    "-logflags=0"
  ];

  syncthingArgs = defaultSyncthingArgs ++ cfg.extraOptions;
in {
  meta.maintainers = [ lib.maintainers.rycee ];

  options = {
    services.syncthing = {
      enable = mkEnableOption ''
        Syncthing, a self-hosted open-source alternative to Dropbox and Bittorrent Sync.
      '';

      cert = mkOption {
        type = with types; nullOr str;
        default = null;
        description = ''
          Path to the `cert.pem` file, which will be copied into Syncthing's
          config directory.
        '';
      };

      key = mkOption {
        type = with types; nullOr str;
        default = null;
        description = ''
          Path to the `key.pem` file, which will be copied into Syncthing's
          config directory.
        '';
      };

      passwordFile = mkOption {
        type = with types; nullOr path;
        default = null;
        description = ''
          Path to the gui password file.
        '';
      };

      overrideDevices = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to delete the devices which are not configured via the
          [devices](#opt-services.syncthing.settings.devices) option.
          If set to `false`, devices added via the web
          interface will persist and will have to be deleted manually.
        '';
      };

      overrideFolders = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to delete the folders which are not configured via the
          [folders](#opt-services.syncthing.settings.folders) option.
          If set to `false`, folders added via the web
          interface will persist and will have to be deleted manually.
        '';
      };

      settings = mkOption {
        type = types.submodule {
          freeformType = settingsFormat.type;
          options = {
            # global options
            options = mkOption {
              default = { };
              description = ''
                The options element contains all other global configuration options
              '';
              type = types.submodule {
                freeformType = settingsFormat.type;
                options = {
                  localAnnounceEnabled = mkOption {
                    type = with types; nullOr bool;
                    default = null;
                    description = ''
                      Whether to send announcements to the local LAN, also use such announcements to find other devices.
                    '';
                  };

                  localAnnouncePort = mkOption {
                    type = with types; nullOr int;
                    default = null;
                    description = ''
                      The port on which to listen and send IPv4 broadcast announcements to.
                    '';
                  };

                  relaysEnabled = mkOption {
                    type = with types; nullOr bool;
                    default = null;
                    description = ''
                      When true, relays will be connected to and potentially used for device to device connections.
                    '';
                  };

                  urAccepted = mkOption {
                    type = with types; nullOr int;
                    default = null;
                    description = ''
                      Whether the user has accepted to submit anonymous usage data.
                      The default, 0, mean the user has not made a choice, and Syncthing will ask at some point in the future.
                      "-1" means no, a number above zero means that that version of usage reporting has been accepted.
                    '';
                  };

                  limitBandwidthInLan = mkOption {
                    type = with types; nullOr bool;
                    default = null;
                    description = ''
                      Whether to apply bandwidth limits to devices in the same broadcast domain as the local device.
                    '';
                  };

                  maxFolderConcurrency = mkOption {
                    type = with types; nullOr int;
                    default = null;
                    description = ''
                      This option controls how many folders may concurrently be in I/O-intensive operations such as syncing or scanning.
                      The mechanism is described in detail in a [separate chapter](https://docs.syncthing.net/advanced/option-max-concurrency.html).
                    '';
                  };
                };
              };
            };

            # device settings
            devices = mkOption {
              default = { };
              description = ''
                Peers/devices which Syncthing should communicate with.

                Note that you can still add devices manually, but those changes
                will be reverted on restart if [overrideDevices](#opt-services.syncthing.overrideDevices)
                is enabled.
              '';
              example = {
                bigbox = {
                  id =
                    "7CFNTQM-IMTJBHJ-3UWRDIU-ZGQJFR6-VCXZ3NB-XUH3KZO-N52ITXR-LAIYUAU";
                  addresses = [ "tcp://192.168.0.10:51820" ];
                };
              };
              type = types.attrsOf (types.submodule ({ name, ... }: {
                freeformType = settingsFormat.type;
                options = {

                  name = mkOption {
                    type = types.str;
                    default = name;
                    description = ''
                      The name of the device.
                    '';
                  };

                  id = mkOption {
                    type = types.str;
                    description = ''
                      The device ID. See <https://docs.syncthing.net/dev/device-ids.html>.
                    '';
                  };

                  autoAcceptFolders = mkOption {
                    type = types.bool;
                    default = false;
                    description = ''
                      Automatically create or share folders that this device advertises at the default path.
                      See <https://docs.syncthing.net/users/config.html?highlight=autoaccept#config-file-format>.
                    '';
                  };

                };
              }));
            };

            # folder settings
            folders = mkOption {
              default = { };
              description = ''
                Folders which should be shared by Syncthing.

                Note that you can still add folders manually, but those changes
                will be reverted on restart if [overrideFolders](#opt-services.syncthing.overrideFolders)
                is enabled.
              '';
              example = literalExpression ''
                {
                  "/home/user/sync" = {
                    id = "syncme";
                    devices = [ "bigbox" ];
                  };
                }
              '';
              type = types.attrsOf (types.submodule ({ name, ... }: {
                freeformType = settingsFormat.type;
                options = {

                  enable = mkOption {
                    type = types.bool;
                    default = true;
                    description = ''
                      Whether to share this folder.
                      This option is useful when you want to define all folders
                      in one place, but not every machine should share all folders.
                    '';
                  };

                  path = mkOption {
                    type = types.str // {
                      check = x:
                        types.str.check x && (lib.substring 0 1 x == "/"
                          || lib.substring 0 2 x == "~/");
                      description = types.str.description
                        + " starting with / or ~/";
                    };
                    default = name;
                    description = ''
                      The path to the folder which should be shared.
                      Only absolute paths (starting with `/`) and paths relative to
                      the user's home directory (starting with `~/`) are allowed.
                    '';
                  };

                  id = mkOption {
                    type = types.str;
                    default = name;
                    description = ''
                      The ID of the folder. Must be the same on all devices.
                    '';
                  };

                  label = mkOption {
                    type = types.str;
                    default = name;
                    description = ''
                      The label of the folder.
                    '';
                  };

                  type = mkOption {
                    type = types.enum [
                      "sendreceive"
                      "sendonly"
                      "receiveonly"
                      "receiveencrypted"
                    ];
                    default = "sendreceive";
                    description = ''
                      Controls how the folder is handled by Syncthing.
                      See <https://docs.syncthing.net/users/config.html#config-option-folder.type>.
                    '';
                  };

                  devices = mkOption {
                    type = with types; listOf str;
                    default = [ ];
                    description = ''
                      The devices this folder should be shared with. Each device must
                      be defined in the [devices](#opt-services.syncthing.settings.devices) option.
                    '';
                  };

                  versioning = mkOption {
                    default = null;
                    description = ''
                      How to keep changed/deleted files with Syncthing.
                      There are 4 different types of versioning with different parameters.
                      See <https://docs.syncthing.net/users/versioning.html>.
                    '';
                    example = literalExpression ''
                      [
                        {
                          versioning = {
                            type = "simple";
                            params.keep = "10";
                          };
                        }
                        {
                          versioning = {
                            type = "trashcan";
                            params.cleanoutDays = "1000";
                          };
                        }
                        {
                          versioning = {
                            type = "staggered";
                            fsPath = "/syncthing/backup";
                            params = {
                              cleanInterval = "3600";
                              maxAge = "31536000";
                            };
                          };
                        }
                        {
                          versioning = {
                            type = "external";
                            params.versionsPath = pkgs.writers.writeBash "backup" '''
                              folderpath="$1"
                              filepath="$2"
                              rm -rf "$folderpath/$filepath"
                            ''';
                          };
                        }
                      ]
                    '';
                    type = with types;
                      nullOr (submodule {
                        freeformType = settingsFormat.type;
                        options = {
                          type = mkOption {
                            type = enum [
                              "external"
                              "simple"
                              "staggered"
                              "trashcan"
                            ];
                            description = ''
                              The type of versioning.
                              See <https://docs.syncthing.net/users/versioning.html>.
                            '';
                          };
                        };
                      });
                  };

                  copyOwnershipFromParent = mkOption {
                    type = types.bool;
                    default = false;
                    description = ''
                      On Unix systems, tries to copy file/folder ownership from
                      the parent directory (the directory it’s located in).
                      Requires running Syncthing as a privileged user, or
                      granting it additional capabilities (e.g. CAP_CHOWN on
                      Linux).
                    '';
                  };
                };
              }));
            };

          };
        };
        default = { };
        description = ''
          Extra configuration options for Syncthing.
          See <https://docs.syncthing.net/users/config.html>.
          Note that this attribute set does not exactly match the documented
          XML format. Instead, this is the format of the JSON REST API. There
          are slight differences. For example, this XML:
          ```xml
          <options>
            <listenAddress>default</listenAddress>
            <minHomeDiskFree unit="%">1</minHomeDiskFree>
          </options>
          ```
          corresponds to the Nix code:
          ```nix
          {
            options = {
              listenAddresses = [
                "default"
              ];
              minHomeDiskFree = {
                unit = "%";
                value = 1;
              };
            };
          }
          ```
        '';
        example = {
          options.localAnnounceEnabled = false;
          gui.theme = "black";
        };
      };

      guiAddress = mkOption {
        type = types.str;
        default = "127.0.0.1:8384";
        description = ''
          The address to serve the web interface at.
        '';
      };

      allProxy = mkOption {
        type = with types; nullOr str;
        default = null;
        example = "socks5://address.com:1234";
        description = ''
          Overwrites the {env}`all_proxy` environment variable for the Syncthing
          process to the given value. This is normally used to let Syncthing
          connect through a SOCKS5 proxy server. See
          <https://docs.syncthing.net/users/proxying.html>.
        '';
      };

      extraOptions = mkOption {
        type = with types; listOf str;
        default = [ ];
        example = [ "--reset-deltas" ];
        description = ''
          Extra command-line arguments to pass to {command}`syncthing`
        '';
      };

      package = mkPackageOption pkgs "syncthing" { };

      tray = mkOption {
        type = with types;
          either bool (submodule {
            options = {
              enable = mkOption {
                type = bool;
                default = false;
                description = "Whether to enable a syncthing tray service.";
              };

              command = mkOption {
                type = str;
                default = "syncthingtray";
                defaultText = literalExpression "syncthingtray";
                example = literalExpression "qsyncthingtray";
                description = "Syncthing tray command to use.";
              };

              package = mkOption {
                type = package;
                default = pkgs.syncthingtray-minimal;
                defaultText = literalExpression "pkgs.syncthingtray-minimal";
                example = literalExpression "pkgs.qsyncthingtray";
                description = "Syncthing tray package to use.";
              };
            };
          });
        default = { enable = false; };
        description = "Syncthing tray service configuration.";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      home.packages = [ (lib.getOutput "man" cfg.package) ];

      systemd.user.services = {
        syncthing = {
          Unit = {
            Description =
              "Syncthing - Open Source Continuous File Synchronization";
            Documentation = "man:syncthing(1)";
            After = [ "network.target" ];
          };

          Service = {
            ExecStartPre =
              lib.mkIf (cfg.cert != null || cfg.key != null) "+${copyKeys}";
            ExecStart = lib.escapeShellArgs syncthingArgs;
            Restart = "on-failure";
            SuccessExitStatus = [ 3 4 ];
            RestartForceExitStatus = [ 3 4 ];
            Environment =
              lib.mkIf (cfg.allProxy != null) { all_proxy = cfg.allProxy; };

            # Sandboxing.
            LockPersonality = true;
            MemoryDenyWriteExecute = true;
            NoNewPrivileges = true;
            PrivateUsers = true;
            RestrictNamespaces = true;
            SystemCallArchitectures = "native";
            SystemCallFilter = "@system-service";
          };

          Install = { WantedBy = [ "default.target" ]; };
        };

        syncthing-init = lib.mkIf (cleanedConfig != { }) {
          Unit = {
            Description = "Syncthing configuration updater";
            Requires = [ "syncthing.service" ];
            After = [ "syncthing.service" ];
          };

          Service = {
            Type = "oneshot";
            ExecStart = updateConfig;
            RuntimeDirectory = "syncthing-init";
            RemainAfterExit = true;
          };

          Install = { WantedBy = [ "default.target" ]; };
        };
      };

      launchd.agents = let
        # agent `syncthing` uses `${syncthing_dir}/${watch_file}` to notify agent `syncthing-init`
        watch_file = ".launchd_update_config";
      in {
        syncthing = {
          enable = true;
          config = {
            ProgramArguments = [
              "${pkgs.writers.writeBash "syncthing-wrapper" ''
                ${copyKeys}                               # simulate systemd's `syncthing-init.Service.ExecStartPre`
                touch "${syncthing_dir}/${watch_file}"    # notify syncthing-init agent
                exec ${lib.escapeShellArgs syncthingArgs}
              ''}"
            ];
            KeepAlive = {
              Crashed = true;
              SuccessfulExit = false;
            };
            ProcessType = "Background";
          };
        };

        syncthing-init = {
          enable = true;
          config = {
            ProgramArguments = [ "${updateConfig}" ];
            WatchPaths = [
              "${config.home.homeDirectory}/Library/Application Support/Syncthing/${watch_file}"
            ];
          };
        };
      };
    })

    (lib.mkIf (lib.isAttrs cfg.tray && cfg.tray.enable) {
      assertions = [
        (lib.hm.assertions.assertPlatform "services.syncthing.tray" pkgs
          lib.platforms.linux)
      ];

      systemd.user.services = {
        ${cfg.tray.package.pname} = {
          Unit = {
            Description = cfg.tray.package.pname;
            Requires = [ "tray.target" ];
            After = [ "graphical-session-pre.target" "tray.target" ];
            PartOf = [ "graphical-session.target" ];
          };

          Service = {
            ExecStart = "${cfg.tray.package}/bin/${cfg.tray.command}";
          };

          Install = { WantedBy = [ "graphical-session.target" ]; };
        };
      };
    })

    # deprecated
    (lib.mkIf (lib.isBool cfg.tray && cfg.tray) {
      assertions = [
        (lib.hm.assertions.assertPlatform "services.syncthing.tray" pkgs
          lib.platforms.linux)
      ];

      systemd.user.services = {
        "syncthingtray" = {
          Unit = {
            Description = "syncthingtray";
            Requires = [ "tray.target" ];
            After = [ "graphical-session-pre.target" "tray.target" ];
            PartOf = [ "graphical-session.target" ];
          };

          Service = {
            ExecStart =
              "${pkgs.syncthingtray-minimal}/bin/syncthingtray --wait";
          };

          Install = { WantedBy = [ "graphical-session.target" ]; };
        };
      };
      warnings = [
        "Specifying 'services.syncthing.tray' as a boolean is deprecated, set 'services.syncthing.tray.enable' instead. See https://github.com/nix-community/home-manager/pull/1257."
      ];
    })
  ];
}
