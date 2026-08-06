{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    attrsToList
    concatLines
    filterAttrsRecursive
    getExe
    hasSuffix
    hm
    isAttrs
    isString
    literalExpression
    maintainers
    makeBinPath
    mkEnableOption
    mkForce
    mkIf
    mkOption
    mkPackageOption
    optionalAttrs
    optionals
    optionalString
    platforms
    types
    ;
  inherit (pkgs)
    coreutils
    formats
    jq
    rsync
    runCommand
    systemd
    writeShellScript
    writeText
    ;

  filterNullOrEmptyAttrsRecursive = filterAttrsRecursive (
    _: v:
    v != null && v != { } && (if isAttrs v then (filterNullOrEmptyAttrsRecursive v) != { } else true)
  );

  jsonFormat = formats.json { };

  cfg = config.services.openlinkhub;
  configDir = "${config.xdg.configHome}/OpenLinkHub";
in

{
  meta.maintainers = with maintainers; [ mikaeladev ];

  options.services.openlinkhub = {
    enable = mkEnableOption "OpenLinkHub";

    package = mkPackageOption pkgs "openlinkhub" { };

    settings = mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = {
        debug = false;
        logLevel = "info";
        metrics = false;
      };
      description = ''
        Configuration to be merged into {file}`config.json`.

        This is equivalent to setting {option}`extraConfigs."config.json"`.
      '';
    };

    dashboard = {
      enable = mkEnableOption "the dashboard";

      address = mkOption {
        type = types.str;
        default = "127.0.0.1";
        example = "127.0.0.2";
        description = ''
          Which local address the dashboard should listen from.
        '';
      };

      port = mkOption {
        type = types.int;
        default = 27003;
        example = 27004;
        description = ''
          Which port the dashboard should listen from.
        '';
      };

      settings = mkOption {
        inherit (jsonFormat) type;
        default = { };
        example = {
          celsius = true;
          languageCode = "en_US";
          pageTitle = "OpenLinkHub WebUI";
        };
        description = ''
          Dashboard configuration to be merged into {file}`dashboard.json`.

          This is equivalent to setting {option}`extraConfigs."dashboard.json"`.
        '';
      };
    };

    memory = {
      enable = mkEnableOption "memory configuration";

      sku = mkOption {
        type = with types; nullOr str;
        default = null;
        example = "CMT64GX5M2B5600Z40";
        description = ''
          The SKU of the device.

          You can find this by running `sudo dmidecode -t memory` and grepping
          by 'Part Number'.

          See the OpenLinkHub [docs] for more information.

          [docs]: https://github.com/jurkovic-nikola/OpenLinkHub/blob/main/docs/memory-configuration.md
        '';
      };

      smb = mkOption {
        type = with types; nullOr (strMatching "i2c-[[:digit:]]");
        default = null;
        example = "i2c-0";
        description = ''
          The SMBus controller for the device.

          You can find this by running `i2cdetect -l` and grepping by 'SMBus',
          with it typically being the first device from the list.

          See the OpenLinkHub [docs] for more information.

          [docs]: https://github.com/jurkovic-nikola/OpenLinkHub/blob/main/docs/memory-configuration.md
        '';
      };

      type = mkOption {
        type = with types; nullOr (ints.between 4 5);
        default = null;
        example = 5;
        description = ''
          Which generation the device belongs to.

          You can find this by running `sudo dmidecode -t memory` and grepping
          by 'Type: DDR[4-5]'.

          See the OpenLinkHub [docs] for a full list of supported devices and
          their generations.

          [docs]: https://github.com/jurkovic-nikola/OpenLinkHub/blob/main/docs/supported-devices.md
        '';
      };
    };

    extraConfigs = mkOption {
      type = with types; attrsOf (either jsonFormat.type lines);
      apply = filterNullOrEmptyAttrsRecursive;
      default = { };
      example = literalExpression ''
        {
          # merges with existing `i2c0.json`
          "database/profiles/i2c0.json" = {
            Active = true;
            Path = "/run/user/1000/OpenLinkHub/database/profiles/i2c0.json";
            Product = "Memory";
            Serial = "i2c0";
            # ...
          };
          # overwrites existing `display.json`
          "display.json" = '''
            [
              {
                "Index": 1,
                "Name": "card1-DP-1",
                "Width": 2560,
                "Height": 1440,
                "Left": false,
                "Top": false
              }
            ]
          ''';
        }
      '';
      description = ''
        Additional files to be written to {file}`$XDG_CONFIG_HOME/OpenLinkHub`.

        Content generated from an attrset will be merged, while content passed
        as lines will be written as is, overwriting any previous data.

        Null values and empty attrsets will be recursively filtered out.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (hm.assertions.assertPlatform "services.openlinkhub" pkgs platforms.linux)
      {
        assertion = ((cfg.settings or { }).enableGamepad or false) == false;
        message = ''
          OpenLinkHub's virtual gamepad is unsupported in user-space,
          requiring raw access to uinput and thus opening the door for
          keyloggers.
        '';
      }
    ]
    ++ (
      let
        assertMemoryOptionNotNull = opt: {
          assertion = cfg.memory.${opt} != null;
          message = ''
            The option `services.openlinkhub.memory.${opt}` must not be null
            when `services.openlinkhub.memory.enable` is set to true.
          '';
        };
      in
      optionals (cfg.memory.enable) [
        (assertMemoryOptionNotNull "sku")
        (assertMemoryOptionNotNull "smb")
        (assertMemoryOptionNotNull "type")
      ]
    );

    services.openlinkhub = {
      extraConfigs = {
        "config.json" =
          let
            settings = filterNullOrEmptyAttrsRecursive (
              (cfg.settings or { })
              // {
                frontend = cfg.dashboard.enable;
                memory = cfg.memory.enable;
              }
              // (optionalAttrs cfg.dashboard.enable {
                listenAddress = cfg.dashboard.address;
                listenPort = cfg.dashboard.port;
              })
              // (optionalAttrs cfg.memory.enable {
                memorySku = cfg.memory.sku;
                memorySmBus = cfg.memory.smb;
                memoryType = cfg.memory.type;
              })
            );
          in
          mkIf (settings != { }) (mkForce settings);

        "dashboard.json" = mkIf (cfg.dashboard.enable && cfg.dashboard.settings != { }) (
          mkForce cfg.dashboard.settings
        );
      };
    };

    systemd.user = {
      services.OpenLinkHub = {
        Unit = {
          After = [ "default.target" ];
          Description = cfg.package.meta.description;
          StartLimitIntervalSec = 60;
          StartLimitBurst = 5;
        };
        Service = {
          ExecStart = getExe cfg.package;
          ExecReload = "${coreutils}/bin/kill -s HUP $MAINPID";
          WorkingDirectory = "%t/OpenLinkHub";
          Restart = "always";
          RestartSec = 5;
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };

      tmpfiles.rules = [
        "D %t/OpenLinkHub - - - - -"

        "L+ %t/OpenLinkHub/static - - - - ${cfg.package}/opt/OpenLinkHub/static"
        "L+ %t/OpenLinkHub/web - - - - ${cfg.package}/opt/OpenLinkHub/web"

        "L+ %t/OpenLinkHub/database - - - - ${configDir}/database"
        "L+ %t/OpenLinkHub/config.json - - - - ${configDir}/config.json"
        "L+ %t/OpenLinkHub/dashboard.json - - - - ${configDir}/dashboard.json"
        "L+ %t/OpenLinkHub/display.json - - - - ${configDir}/display.json"
      ];
    };

    home.activation = {
      checkOpenLinkHubSetup =
        let
          udevRuleDir = "/etc/udev/rules.d";
          udevRuleName = "70-openlinkhub.rules";

          udevRule = runCommand udevRuleName { } ''
            cp ${cfg.package}${udevRuleDir}/99-openlinkhub.rules $out

            sed -i '/^KERNEL=="uinput"/d' $out

            substituteInPlace $out --replace-fail \
              'OWNER="openlinkhub"' 'TAG+="uaccess"'

            ${optionalString cfg.memory.enable ''
              echo 'KERNEL=="${cfg.memory.smb}", MODE="0660", TAG+="uaccess"' \
                >> $out
            ''}
          '';

          setupScript = writeShellScript "openlinkhub-setup" ''
            set -euo pipefail

            PATH="${makeBinPath [ systemd ]}''${PATH:+:}$PATH"

            echo "Linking udev rule..."
            sudo mkdir -p ${udevRuleDir}
            sudo ln -fs ${udevRule} ${udevRuleDir}/${udevRuleName}
            sudo ln -fs ${udevRuleDir}/${udevRuleName} \
              ''${NIX_STATE_DIR:-/nix/var/nix}/gcroots/${udevRuleName}

            echo "Reloading udev rules..."
            sudo udevadm control --reload-rules
            sudo udevadm trigger

            echo "Restarting OpenLinkHub..."
            systemctl --user restart OpenLinkHub.service

            echo "Success!"
          '';
        in
        hm.dag.entryAnywhere ''
          if [ ! -L ${udevRuleDir}/${udevRuleName} ]; then
            warnEcho "To finish setting up OpenLinkHub, run"
            warnEcho "  ${setupScript}"
          elif ! cmp -s ${udevRuleDir}/${udevRuleName} ${udevRule}; then
            warnEcho "OpenLinkHub requires an update, run"
            warnEcho "  ${setupScript}"
          fi
        '';

      configureOpenLinkHub =
        let
          concatMapLines = f: list: concatLines (map f list);

          withSuffix = suffix: value: if (hasSuffix suffix value) then value else (value + suffix);

          generatedLines = concatMapLines (
            { name, value }:
            let
              writerFn = if isString value then writeText else jsonFormat.generate;
              bashFn = if isString value then "writeConfig" else "mergeConfig";

              configPath = configDir + "/" + (withSuffix ".json" name);
              configFile = writerFn (baseNameOf configPath) value;
            in
            "run ${bashFn} '${configFile}' '${configPath}'"
          ) (attrsToList cfg.extraConfigs);
        in
        hm.dag.entryAfter [ "writeBoundary" ] ''
          writeConfig() {
            cat "$1" > "$2"
          }

          mergeConfig() {
            if [ -e "$2" ]; then
              local tempFile
              tempFile=$(mktemp)

              trap "rm -f $tempFile" EXIT

              ${getExe jq} -sS 'add' "$2" "$1" > "$tempFile"

              writeConfig "$tempFile" "$2"
            else
              writeConfig "$1" "$2"
            fi
          }

          run mkdir -p "${configDir}/database"

          run ${getExe rsync} -a --chmod=D755,F644 --ignore-existing \
            ${cfg.package}/opt/OpenLinkHub/database/ '${configDir}/database'

          ${generatedLines}

          unset -f writeConfig mergeConfig
        '';
    };
  };
}
