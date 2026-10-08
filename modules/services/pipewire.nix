{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    attrByPath
    concatLists
    concatMap
    escapeShellArgs
    flatten
    hasSuffix
    hm
    literalExpression
    maintainers
    mapAttrsToList
    mkEnableOption
    mkIf
    mkOption
    optional
    optionals
    path
    platforms
    types
    ;
  inherit (pkgs)
    buildEnv
    formats
    runCommand
    symlinkJoin
    writeTextDir
    ;

  jsonFormat = formats.json { };
  jsonAttrs = types.attrsOf jsonFormat.type;

  cfg = config.services.pipewire;
  systemdCfg = config.systemd.user;
in

{
  meta.maintainers = with maintainers; [ mikaeladev ];

  options.services.pipewire = {
    enable = mkEnableOption "PipeWire configurations";

    configs = mkOption {
      type = jsonAttrs;
      default = { };
      example = {
        "10-clock-rate" = {
          "context.properties" = {
            "default.clock.rate" = 44100;
          };
        };
        "11-no-upmixing" = {
          "stream.properties" = {
            "channelmix.upmix" = false;
          };
        };
      };
      description = ''
        Set of configuration files for the PipeWire server.

        Every item in this attrset becomes a separate drop-in file in
        {file}`$XDG_CONFIG_HOME/pipewire/pipewire.conf.d/`.

        See `man pipewire.conf` for details, and the [PipeWire wiki] for
        examples.

        [pipewire wiki]: https://gitlab.freedesktop.org/pipewire/pipewire/-/wikis/Config-PipeWire
      '';
    };

    clientConfigs = mkOption {
      type = jsonAttrs;
      default = { };
      example = {
        "10-no-resample" = {
          "stream.properties" = {
            "resample.disable" = true;
          };
        };
      };
      description = ''
        Set of configuration files for the PipeWire client library.

        Every item in this attrset becomes a separate drop-in file in
        {file}`$XDG_CONFIG_HOME/pipewire/client.conf.d/`.

        See the [PipeWire wiki][wiki] for examples.

        [wiki]: https://gitlab.freedesktop.org/pipewire/pipewire/-/wikis/Config-client
      '';
    };

    jackConfigs = mkOption {
      type = jsonAttrs;
      default = { };
      example = {
        "20-hide-midi" = {
          "jack.properties" = {
            "jack.show-midi" = false;
          };
        };
      };
      description = ''
        Set of configuration files for the PipeWire JACK server and client
        library.

        Every item in this attrset becomes a separate drop-in file in
        {file}`$XDG_CONFIG_HOME/pipewire/jack.conf.d/`.

        See the [PipeWire wiki] for examples.

        [pipewire wiki]: https://gitlab.freedesktop.org/pipewire/pipewire/-/wikis/Config-JACK
      '';
    };

    pulseConfigs = mkOption {
      type = jsonAttrs;
      default = { };
      example = {
        "15-force-s16-info" = {
          "pulse.rules" = [
            {
              matches = [ { "application.process.binary" = "my-broken-app"; } ];
              actions = {
                quirks = [ "force-s16-info" ];
              };
            }
          ];
        };
      };
      description = ''
        Set of configuration files for the PipeWire PulseAudio server.

        Every item in this attrset becomes a separate drop-in file in
        {file}`$XDG_CONFIG_HOME/pipewire/pipewire-pulse.conf.d/`.

        See `man pipewire-pulse.conf` for details, and the [PipeWire wiki] for
        examples.

        [pipewire wiki]: https://gitlab.freedesktop.org/pipewire/pipewire/-/wikis/Config-PulseAudio
      '';
    };

    configPackages = mkOption {
      type = with types; listOf package;
      default = [ ];
      example = literalExpression ''
        [
          (pkgs.writeTextDir "share/pipewire/pipewire.conf.d/10-loopback.conf" '''
            context.modules = [
              {
                name = libpipewire-module-loopback
                args = {
                  node.description = "Scarlett Focusrite Line 1"
                  capture.props = {
                    audio.position = [ FL ]
                    stream.dont-remix = true
                    node.target = "alsa_input.usb-Focusrite_Scarlett_Solo_USB_Y7ZD17C24495BC-00.analog-stereo"
                    node.passive = true
                  }
                  playback.props = {
                    node.name = "SF_mono_in_1"
                    media.class = "Audio/Source"
                    audio.position = [ MONO ]
                  }
                }
              }
            ]
          ''')
        ]'';
      description = ''
        List of packages that provide PipeWire configurations, in the form of
        {file}`share/pipewire/*/*.conf` files.

        LV2 dependencies will be picked up from config packages automatically
        via `passthru.requiredLv2Packages`.
      '';
    };

    extraLv2Packages = mkOption {
      type = with types; listOf package;
      default = [ ];
      example = literalExpression "[ pkgs.lsp-plugins ]";
      description = ''
        List of packages that provide LV2 plugins, in the form of
        {file}`lib/lv2/*` files.

        LV2 dependencies will be picked up from config packages automatically
        via `passthru.requiredLv2Packages`, so they don't need to be set here.
      '';
    };

    extraLadspaPackages = mkOption {
      type = with types; listOf package;
      default = [ ];
      example = literalExpression "[ pkgs.noisetorch-ladspa ]";
      description = ''
        List of packages that provide LADSPA plugins, in the form of
        {file}`lib/ladspa/*` files.

        LADSPA dependencies will be picked up from config packages automatically
        via `passthru.requiredLadspaPackages`, so they don't need to be set here.
      '';
    };

    wireplumber = {
      enable = mkEnableOption "WirePlumber configurations";

      configs = mkOption {
        type = jsonAttrs;
        default = { };
        example = {
          log-level-debug = {
            "context.properties" = {
              "log.level" = "D";
            };
          };
          wh-1000xm3-ldac-hq = {
            "monitor.bluez.rules" = [
              {
                matches = [
                  {
                    "device.name" = "~bluez_card.*";
                    "device.product.id" = "0x0cd3";
                    "device.vendor.id" = "usb:054c";
                  }
                ];
                actions = {
                  update-props = {
                    "bluez5.a2dp.ldac.quality" = "hq";
                  };
                };
              }
            ];
          };
        };
        description = ''
          Set of configuration files for the WirePlumber daemon.

          Every item in this attrset becomes a separate drop-in file in
          {file}`$XDG_CONFIG_HOME/wireplumber/wireplumber.conf.d/`.

          See the [NixOS option] for details.

          [nixos option]: https://search.nixos.org/options?channel=25.11&type=options&show=services.pipewire.wireplumber.extraConfig
        '';
      };

      configPackages = mkOption {
        type = with types; listOf package;
        default = [ ];
        example = literalExpression ''
          [
            (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/10-bluez.conf" '''
              monitor.bluez.properties = {
                bluez5.roles = [ a2dp_sink a2dp_source bap_sink bap_source hsp_hs hsp_ag hfp_hf hfp_ag ]
                bluez5.codecs = [ sbc sbc_xq aac ]
                bluez5.enable-sbc-xq = true
                bluez5.hfphsp-backend = "native"
              }
            ''')
          ]'';
        description = ''
          List of packages that provide WirePlumber configurations, in the form
          of {file}`share/wireplumber/*/*.conf` files.

          LV2 dependencies will be picked up from config packages automatically
          via `passthru.requiredLv2Packages`.
        '';
      };

      scripts = mkOption {
        type = with types; attrsOf lines;
        default = { };
        example = {
          "test/hello-world.lua" = ''
            print("Hello, world!")
          '';
        };
        description = ''
          Set of lua scripts to be used by WirePlumber configuration files.

          Every item in this attrset becomes a separate drop-in file in
          {file}`$XDG_DATA_HOME/wireplumber/scripts/`.

          See the [NixOS option] for details.

          [nixos option]: https://search.nixos.org/options?channel=25.11&type=options&show=services.pipewire.wireplumber.extraScripts
        '';
      };

      scriptPackages = mkOption {
        type = with types; listOf package;
        default = [ ];
        example = literalExpression ''
          [
            (pkgs.writeTextDir "share/wireplumber/scripts/test/hello-world.lua" '''
              print("Hello, world!")
            ''')
          ]'';
        description = ''
          List of packages that provide WirePlumber scripts, in the form of
          {file}`share/wireplumber/scripts/*/*.lua` files.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (hm.assertions.assertPlatform "services.pipewire" pkgs platforms.linux)
    ];

    xdg =
      let
        withSuffix = suffix: value: if (hasSuffix suffix value) then value else (value + suffix);

        mapConfigsToPaths =
          parent: subdir: configs:
          mapAttrsToList (
            name: value:
            let
              filename = withSuffix ".conf" name;
              filepath = path.subpath.join [
                "share/${parent}/${subdir}.conf.d"
                filename
              ];
            in
            runCommand "pipewire-${name}-config" { } ''
              mkdir -p $out/${dirOf filepath}
              ln -s ${jsonFormat.generate name value} $out/${filepath}
            ''
          ) configs;

        condMapConfigsToPaths =
          parent: subdir: configs:
          optional (configs != { }) (mapConfigsToPaths parent subdir configs);

        pipewireConfigPaths =
          cfg.configPackages
          ++ concatLists [
            (condMapConfigsToPaths "pipewire" "pipewire" cfg.configs)
            (condMapConfigsToPaths "pipewire" "client" cfg.clientConfigs)
            (condMapConfigsToPaths "pipewire" "jack" cfg.jackConfigs)
            (condMapConfigsToPaths "pipewire" "pipewire-pulse" cfg.pulseConfigs)
          ];

        wireplumberConfigPaths =
          cfg.wireplumber.configPackages
          ++ (condMapConfigsToPaths "wireplumber" "wireplumber" cfg.wireplumber.configs);

        wireplumberScriptPaths =
          cfg.wireplumber.scriptPackages
          ++ (optional (cfg.wireplumber.scripts != { }) (
            mapAttrsToList (
              name: content:
              let
                filename = withSuffix ".lua" name;
                filepath = path.subpath.join [
                  "share/wireplumber/scripts"
                  filename
                ];
              in
              writeTextDir filepath content
            ) cfg.wireplumber.scripts
          ));

        onChange = ''
          if [[ ! -v PIPEWIRE_RELOAD ]]; then
            PIPEWIRE_RELOAD=1
          fi
        '';
      in
      {
        configFile = {
          "pipewire" = {
            inherit onChange;
            enable = pipewireConfigPaths != [ ];
            source = symlinkJoin {
              name = "pipewire-configs";
              paths = pipewireConfigPaths;
              stripPrefix = "/share/pipewire";
            };
          };
          "wireplumber" = mkIf cfg.wireplumber.enable {
            inherit onChange;
            enable = wireplumberConfigPaths != [ ];
            source = symlinkJoin {
              name = "wireplumber-configs";
              paths = wireplumberConfigPaths;
              stripPrefix = "/share/wireplumber";
            };
          };
        };

        dataFile = {
          "wireplumber" = mkIf cfg.wireplumber.enable {
            inherit onChange;
            enable = wireplumberScriptPaths != [ ];
            source = symlinkJoin {
              name = "wireplumber-scripts";
              paths = wireplumberScriptPaths;
              stripPrefix = "/share/wireplumber";
            };
          };
        };
      };

    systemd.user.sessionVariables =
      let
        lv2PluginPaths =
          cfg.extraLv2Packages
          ++ flatten (
            concatMap (p: attrByPath [ "passthru" "requiredLv2Packages" ] [ ] p) (
              cfg.configPackages ++ (optionals cfg.wireplumber.enable cfg.wireplumber.configPackages)
            )
          );

        lv2Plugins = buildEnv {
          name = "pipewire-lv2-plugins";
          paths = lv2PluginPaths;
          pathsToLink = [ "/lib/lv2" ];
        };

        ladspaPluginsPaths =
          cfg.extraLadspaPackages
          ++ flatten (
            concatMap (p: attrByPath [ "passthru" "requiredLadspaPackages" ] [ ] p) (
              cfg.configPackages ++ (optionals cfg.wireplumber.enable cfg.wireplumber.configPackages)
            )
          );

        ladspaPlugins = pkgs.buildEnv {
          name = "pipewire-ladspa-plugins";
          paths = ladspaPluginsPaths;
          pathsToLink = [ "/lib/ladspa" ];
        };
      in
      {
        LV2_PATH = mkIf (lv2PluginPaths != [ ]) "${lv2Plugins}/lib/lv2\${LV2_PATH:+:$LV2_PATH}";
        LADSPA_PATH = mkIf (
          ladspaPlugins != [ ]
        ) "${ladspaPlugins}/lib/ladspa\${LADSPA_PATH:+:$LADSPA_PATH}";
      };

    home.activation.reloadPipewire =
      let
        pipewireUnits = escapeShellArgs (
          [
            "pipewire"
            "pipewire-pulse"
          ]
          ++ optional cfg.wireplumber.enable "wireplumber"
        );

        ensureSystemd = ''
          env XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}" \
            PATH="${dirOf systemdCfg.systemctlPath}:$PATH" \
        '';

        systemctl = "${ensureSystemd} systemctl";
      in
      mkIf systemdCfg.enable (
        hm.dag.entryAfter [ "onFilesChange" "reloadSystemd" ] ''
          if [[ -v PIPEWIRE_RELOAD ]]; then
            if [[ -v DRY_RUN ]]; then
              echo 'systemctl --user restart ${pipewireUnits}'
            else
              systemdStatus=$(${systemctl} --user is-system-running 2>&1 || true)

              if [[ $systemdStatus == 'running' ]]; then
                ${systemctl} --user restart ${pipewireUnits}
              else
                echo "User systemd daemon not running. Skipping pipewire reload."
              fi

              unset systemdStatus
            fi

            unset PIPEWIRE_RELOAD
          fi
        ''
      );
  };
}
