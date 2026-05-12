{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.wayland.windowManager.hyprland;

  toLua = lib.generators.toLua { };

  settingValueType =
    with lib.types;
    nullOr (oneOf [
      bool
      int
      float
      str
      path
      (attrsOf settingValueType)
      (listOf settingValueType)
    ])
    // {
      description = "Hyprland configuration value";
    };

  variables = builtins.concatStringsSep " " cfg.systemd.variables;
  extraCommands = builtins.concatStringsSep " " (map (f: "&& ${f}") cfg.systemd.extraCommands);
  systemdActivationCommand = "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd ${variables} ${extraCommands}";

  pluginPath =
    entry: if lib.types.package.check entry then "${entry}/lib/lib${entry.pname}.so" else entry;

  reloadConfig = ''
    (
      XDG_RUNTIME_DIR=''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
      if [[ -d "/tmp/hypr" || -d "$XDG_RUNTIME_DIR/hypr" ]]; then
        for i in $(${cfg.finalPackage}/bin/hyprctl instances -j | jq ".[].instance" -r); do
          ${cfg.finalPackage}/bin/hyprctl -i "$i" reload config-only
        done
      fi
    )
  '';
in
{
  meta.maintainers = [ lib.maintainers.fufexan ];

  # A few option removals and renames to aid those migrating from the upstream
  # module.
  imports = [
    (lib.mkRemovedOptionModule # \
      [ "wayland" "windowManager" "hyprland" "disableAutoreload" ]
      "Autoreloading now always happens"
    )

    (lib.mkRemovedOptionModule # \
      [ "wayland" "windowManager" "hyprland" "recommendedEnvironment" ]
      "Recommended environment variables are now always set"
    )

    (lib.mkRemovedOptionModule # \
      [ "wayland" "windowManager" "hyprland" "xwayland" "hidpi" ]
      "HiDPI patches are deprecated. Refer to <https://wiki.hypr.land/Configuring/Advanced-and-Cool/XWayland>"
    )

    (lib.mkRemovedOptionModule # \
      [ "wayland" "windowManager" "hyprland" "nvidiaPatches" ] # \
      "Nvidia patches are no longer needed"
    )
    (lib.mkRemovedOptionModule # \
      [ "wayland" "windowManager" "hyprland" "enableNvidiaPatches" ] # \
      "Nvidia patches are no longer needed"
    )

    (lib.mkRenamedOptionModule # \
      [ "wayland" "windowManager" "hyprland" "systemdIntegration" ] # \
      [ "wayland" "windowManager" "hyprland" "systemd" "enable" ]
    )
  ];

  options.wayland.windowManager.hyprland = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to enable configuration for Hyprland, a tiling Wayland
        compositor that doesn't sacrifice on its looks.

        ::: {.note}
        This module configures Hyprland and adds it to your user's {env}`PATH`,
        but does not make certain system-level changes. NixOS users should
        enable the NixOS module with {option}`programs.hyprland.enable`, which
        makes system-level changes such as adding a desktop session entry.
        :::
      '';
    };

    package = lib.mkPackageOption pkgs "hyprland" {
      nullable = true;
      extraDescription = "Set this to null if you use the NixOS module to install Hyprland.";
    };

    portalPackage = lib.mkPackageOption pkgs "xdg-desktop-portal-hyprland" {
      nullable = true;
    };

    finalPackage = lib.mkOption {
      type = with lib.types; nullOr package;
      readOnly = true;
      default =
        if cfg.package != null then
          cfg.package.override { enableXWayland = cfg.xwayland.enable; }
        else
          null;
      defaultText = lib.literalMD "`wayland.windowManager.hyprland.package` with applied configuration";
      description = ''
        The Hyprland package after applying configuration.
      '';
    };

    finalPortalPackage = lib.mkOption {
      type = with lib.types; nullOr package;
      readOnly = true;
      default =
        if (cfg.portalPackage != null) then
          if cfg.finalPackage != null then
            cfg.portalPackage.override { hyprland = cfg.finalPackage; }
          else
            cfg.portalPackage
        else
          null;
      defaultText = lib.literalMD ''
        `wayland.windowManager.hyprland.portalPackage` with
                `wayland.windowManager.hyprland.finalPackage` override'';
      description = ''
        The xdg-desktop-portal-hyprland package after overriding its hyprland input.
      '';
    };

    plugins = lib.mkOption {
      type = with lib.types; listOf (either package path);
      default = [ ];
      description = ''
        List of Hyprland plugins to use. Can either be packages or
        absolute plugin paths.
      '';
    };

    configType = lib.mkOption {
      type = lib.types.enum [
        "hyprlang"
        "lua"
      ];
      inherit
        (lib.hm.deprecations.mkStateVersionOptionDefault {
          inherit (config.home) stateVersion;
          since = "26.05";
          optionPath = [
            "wayland"
            "windowManager"
            "hyprland"
            "configType"
          ];
          legacy.value = "hyprlang";
          current.value = "lua";
        })
        default
        defaultText
        ;
      description = ''
        The type of Hyprland configuration to generate.

        `hyprlang` writes {file}`$XDG_CONFIG_HOME/hypr/hyprland.conf`.
        `lua` writes {file}`$XDG_CONFIG_HOME/hypr/hyprland.lua`.
      '';
    };

    systemd = {
      enable = lib.mkEnableOption null // {
        default = true;
        description = ''
          Whether to enable {file}`hyprland-session.target` on
          hyprland startup. This links to `graphical-session.target`.
          Some important environment variables will be imported to systemd
          and D-Bus user environment before reaching the target, including
          - `DISPLAY`
          - `HYPRLAND_INSTANCE_SIGNATURE`
          - `WAYLAND_DISPLAY`
          - `XDG_CURRENT_DESKTOP`
          - `XDG_SESSION_TYPE`
        '';
      };

      variables = lib.mkOption {
        type = with lib.types; listOf str;
        default = [
          "DISPLAY"
          "HYPRLAND_INSTANCE_SIGNATURE"
          "WAYLAND_DISPLAY"
          "XDG_CURRENT_DESKTOP"
          "XDG_SESSION_TYPE"
        ];
        example = [ "--all" ];
        description = ''
          Environment variables to be imported in the systemd & D-Bus user
          environment.
        '';
      };

      extraCommands = lib.mkOption {
        type = with lib.types; listOf str;
        default = [
          "systemctl --user stop hyprland-session.target"
          "systemctl --user start hyprland-session.target"
        ];
        description = "Extra commands to be run after D-Bus activation.";
      };

      enableXdgAutostart = lib.mkEnableOption ''
        autostart of applications using
        {manpage}`systemd-xdg-autostart-generator(8)`'';
    };

    xwayland.enable = lib.mkEnableOption "XWayland" // {
      default = true;
      description = ''
        Whether or not to enable XWayland.

        Overrides the `enableXWayland` option of the Hyprland package.

        In newer versions of Hyprland, you can use the {option}`wayland.windowManager.hyprland.settings.xwayland`
        option to avoid recompiling Hyprland.
      '';
    };

    settings = lib.mkOption {
      type = settingValueType;
      default = { };
      description = ''
        Hyprland configuration written in Nix. Entries with the same key
        should be written as lists. Variables' and colors' names should be
        quoted. See <https://wiki.hypr.land> for more examples.

        ::: {.note}
        Use the [](#opt-wayland.windowManager.hyprland.plugins) option to
        declare plugins.
        :::

        When {option}`wayland.windowManager.hyprland.configType` is `"lua"`,
        each attribute maps to an `hl.<name>(...)` call. List values generate
        one call per element.

        Attribute values with an `_args` list generate multi-argument calls.
        Values created with `lib.generators.mkLuaInline` are rendered as raw
        Lua expressions.

      '';
      example = lib.literalExpression ''
        {
          config = {
            general = {
              gaps_in = 5;
              gaps_out = 20;
              border_size = 2;
            };

            decoration = {
              rounding = 10;
            };
          };

          bind = [
            {
              _args = [
                "SUPER + Q"
                (lib.generators.mkLuaInline "hl.dsp.window.close()")
                { locked = true; }
              ];
            }
            {
              _args = [
                "SUPER + RETURN"
                (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"kitty\")")
              ];
            }
            {
              _args = [
                "ALT + R"
                (lib.generators.mkLuaInline "hl.dsp.submap(\"resize\")")
              ];
            }
          ];

          define_submap = {
            _args = [
              "resize"
              (lib.generators.mkLuaInline "function()\n  hl.bind(\"right\", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true })\n  hl.bind(\"left\", hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true })\n  hl.bind(\"escape\", hl.dsp.submap(\"reset\"))\nend")
            ];
          };

          window_rule = {
            match.class = "kitty";
            border_size = 2;
          };

          on = {
            _args = [
              "hyprland.start"
              (lib.generators.mkLuaInline "function()\n  hl.exec_cmd(\"waybar\")\nend")
            ];
          };
        }
      '';
    };

    submaps = lib.mkOption {
      description = ''
        Attribute set of Hyprland submaps.

        See <https://wiki.hypr.land/Configuring/Basics/Binds/#submaps> to learn about submaps.
      '';
      default = { };
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            onDispatch = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = ''
                Submap to use after a dispatch. Can either be a name or `reset` to disable submap after any dispatch.
              '';
              example = "reset";
            };
            settings = lib.mkOption {
              type = (with lib.types; attrsOf (listOf settingValueType)) // {
                description = "Hyprland binds";
              };
              default = { };
              description = ''
                Hyprland binds to be put in the submap.

                String entries render only when
                {option}`wayland.windowManager.hyprland.configType` is
                `"hyprlang"`.

                Attribute set entries render only when
                {option}`wayland.windowManager.hyprland.configType` is `"lua"`.
                Attribute values with an `_args` list generate multi-argument
                calls. Values created with `lib.generators.mkLuaInline` are
                rendered as raw Lua expressions.
              '';
              example = lib.literalExpression ''
                {
                  binde = [
                   ", right, resizeactive, 10 0"
                   ", left, resizeactive, -10 0"
                   ", up, resizeactive, 0 -10"
                   ", down, resizeactive, 0 10"
                  ];

                  bind = [
                    ", escape, submap, reset"
                    {
                      _args = [
                        "escape"
                        (lib.generators.mkLuaInline "hl.dsp.submap(\"reset\")")
                      ];
                    }
                  ];
                }
              '';
            };
          };
        }
      );
      example = lib.literalExpression ''
        {
          # submap to change window focus with vim keys
          move_focus = {
            settings = {
              bind = [
                ", h, movefocus, l"
                ", j, movefocus, d"
                ", k, movefocus, u"
                ", l, movefocus, r"

                ", escape, submap, reset"
              ];
            };
          };

          other_submap = {
            settings = {
              # ...
            };
          };
        }
      '';
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      example = ''
        hl.on("window.open", function()
          hl.timer(function()
            hl.dispatch(hl.dsp.exec_cmd("notify-send 'Window opened'"))
          end, {
            timeout = 100,
            type = "oneshot",
          })
        end)
      '';
      description = ''
        Extra configuration content appended to the generated Hyprland file.
      '';
    };

    sourceFirst =
      lib.mkEnableOption ''
        putting source entries at the top of the configuration
      ''
      // {
        default = true;
      };

    importantPrefixes = lib.mkOption {
      type = with lib.types; listOf str;
      default = [
        "$"
        "bezier"
        "curve"
        "name"
        "output"
      ];
      example = [
        "$"
        "bezier"
      ];
      description = ''
        List of prefix of attributes to source at the top of the config.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "wayland.windowManager.hyprland" pkgs lib.platforms.linux)
      {
        assertion = !builtins.hasAttr "reset" cfg.submaps;
        message = "Submaps can't be named 'reset'. The name 'reset' is reserved in order to have a way to switch to the default submap; as if 'reset' was its name.";
      }
    ];

    warnings =
      let
        inconsistent =
          (cfg.systemd.enable || cfg.plugins != [ ])
          && cfg.extraConfig == ""
          && cfg.settings == { }
          && cfg.submaps == { };
        warning = "You have enabled hyprland.systemd.enable or listed plugins in hyprland.plugins but do not have any configuration in hyprland.settings, hyprland.extraConfig or hyprland.submaps. This is almost certainly a mistake.";

        filterNonBinds =
          attrs: builtins.filter (n: builtins.match "bind[[:lower:]]*" n == null) (builtins.attrNames attrs);

        # attrset of { <submap name> = <list of non bind* keys>; } for all submaps
        submapWarningsAttrset = builtins.mapAttrs (
          _name: submap: filterNonBinds submap.settings
        ) cfg.submaps;

        submapWarnings = lib.mapAttrsToList (submapName: nonBinds: ''
          wayland.windowManager.hyprland.submaps."${submapName}".settings: found non-bind entries: [${toString nonBinds}], which will have no effect in a submap
        '') (lib.filterAttrs (_n: v: v != [ ]) submapWarningsAttrset);
      in
      submapWarnings ++ lib.optional inconsistent warning;

    home.packages = lib.mkIf (cfg.package != null) (
      [ cfg.finalPackage ] ++ lib.optional cfg.xwayland.enable pkgs.xwayland
    );

    xdg.configFile = lib.mkMerge [
      {
        "hypr/hyprland.conf" = lib.mkIf (cfg.configType == "hyprlang") (
          let
            importantPrefixes = cfg.importantPrefixes ++ lib.optional cfg.sourceFirst "source";

            pluginsToHyprconf =
              plugins:
              lib.hm.generators.toHyprconf {
                attrs = {
                  "exec-once" = map (entry: "hyprctl plugin load ${pluginPath entry}") plugins;
                };
                inherit importantPrefixes;
              };

            hyprlangSubmapSettings =
              settings:
              lib.filterAttrs (_: values: values != [ ]) (
                lib.mapAttrs (_: builtins.filter lib.isString) settings
              );

            hyprlangSubmaps = lib.filterAttrs (
              _: submap: hyprlangSubmapSettings submap.settings != { }
            ) cfg.submaps;

            mkSubMap = name: attrs: ''
              submap = ${name}${lib.optionalString (attrs.onDispatch != "") ", ${attrs.onDispatch}"}
              ${
                lib.hm.generators.toHyprconf {
                  attrs = hyprlangSubmapSettings attrs.settings;
                  indentLevel = 0;
                }
              }submap = reset
            '';

            submapsToHyprConf = lib.concatMapAttrsStringSep "\n" mkSubMap hyprlangSubmaps;

            shouldGenerate =
              cfg.systemd.enable
              || cfg.extraConfig != ""
              || cfg.settings != { }
              || cfg.plugins != [ ]
              || hyprlangSubmaps != { };
          in
          lib.mkIf shouldGenerate {
            text =
              lib.optionalString cfg.systemd.enable ''
                exec-once = ${systemdActivationCommand}
              ''
              + lib.optionalString (cfg.plugins != [ ]) (pluginsToHyprconf cfg.plugins)
              + lib.optionalString (cfg.settings != { }) (
                lib.hm.generators.toHyprconf {
                  attrs = cfg.settings;
                  inherit importantPrefixes;
                }
              )
              + lib.optionalString (hyprlangSubmaps != { }) submapsToHyprConf
              + lib.optionalString (cfg.extraConfig != "") cfg.extraConfig;

            onChange = lib.mkIf (cfg.package != null) reloadConfig;
          }
        );
      }
      {
        "hypr/hyprland.lua" = lib.mkIf (cfg.configType == "lua") (
          let
            pluginLoadCommands = map (entry: "hyprctl plugin load ${pluginPath entry}") cfg.plugins;
            startupCommands =
              lib.optionals cfg.systemd.enable [ systemdActivationCommand ] ++ pluginLoadCommands;

            renderArgs =
              value:
              if lib.isAttrs value && value ? _args then
                lib.concatMapStringsSep ", " toLua value._args
              else
                toLua value;

            renderSection =
              name: text:
              lib.optionalString (text != "") ''
                -- ${name}
                ${text}
              '';

            renderSettings =
              let
                names = lib.sort lib.lessThan (lib.attrNames cfg.settings);
                importantNames = lib.unique (
                  lib.concatMap (
                    prefix: builtins.filter (name: lib.hasPrefix prefix name) names
                  ) cfg.importantPrefixes
                );
                orderedNames = importantNames ++ builtins.filter (name: !(builtins.elem name importantNames)) names;
                renderCall = name: value: "hl.${name}(${renderArgs value})\n";
                renderCalls =
                  name: value:
                  lib.concatMapStrings (renderCall name) (if builtins.isList value then value else [ value ]);
              in
              lib.concatMapStrings (
                name: renderSection "settings.${name}" (renderCalls name cfg.settings.${name})
              ) orderedNames;

            renderStartHook =
              if startupCommands == [ ] then
                ""
              else
                renderSection "startup" ''
                  hl.on("hyprland.start", function()
                  ${lib.concatMapStrings (command: "  hl.exec_cmd(${toLua command})\n") startupCommands}end)
                '';

            renderSubmaps =
              let
                renderLuaArg = value: lib.replaceStrings [ "\n" ] [ "\n  " ] (renderArgs value);
                renderCall = name: value: "  hl.${name}(${renderLuaArg value})\n";
                renderCalls =
                  name: values:
                  lib.concatMapStrings (renderCall name) (builtins.filter (value: !lib.isString value) values);
                renderSubmap =
                  name: submap:
                  renderSection "submaps.${name}" (
                    "hl.define_submap(${toLua name}"
                    + lib.optionalString (submap.onDispatch != "") ", ${toLua submap.onDispatch}"
                    + ", function()\n"
                    + lib.concatMapStrings (settingName: renderCalls settingName submap.settings.${settingName}) (
                      lib.sort lib.lessThan (lib.attrNames submap.settings)
                    )
                    + "end)\n"
                  );
                hasLuaSettings =
                  submap:
                  lib.any (values: builtins.any (value: !lib.isString value) values) (lib.attrValues submap.settings);
                luaSubmaps = lib.filterAttrs (_: hasLuaSettings) cfg.submaps;
                names = lib.sort lib.lessThan (lib.attrNames luaSubmaps);
              in
              lib.concatMapStrings (name: renderSubmap name luaSubmaps.${name}) names;

            hasLuaSubmaps = lib.any (
              submap:
              lib.any (values: builtins.any (value: !lib.isString value) values) (lib.attrValues submap.settings)
            ) (lib.attrValues cfg.submaps);

            shouldGenerate =
              cfg.systemd.enable
              || cfg.extraConfig != ""
              || cfg.settings != { }
              || cfg.plugins != [ ]
              || hasLuaSubmaps;
          in
          lib.mkIf shouldGenerate {
            text = ''
              -- Generated by Home Manager.
              -- See https://wiki.hypr.land/Configuring/Start/

            ''
            + renderSettings
            + renderSubmaps
            + renderStartHook
            + renderSection "extraConfig" cfg.extraConfig;

            onChange = lib.mkIf (cfg.package != null) reloadConfig;
          }
        );
      }
    ];

    xdg.portal = {
      enable = cfg.finalPortalPackage != null;
      extraPortals = lib.mkIf (cfg.finalPortalPackage != null) [ cfg.finalPortalPackage ];
      configPackages = lib.mkIf (cfg.finalPackage != null) (lib.mkDefault [ cfg.finalPackage ]);
    };

    systemd.user.targets.hyprland-session = lib.mkIf cfg.systemd.enable {
      Unit = {
        Description = "Hyprland compositor session";
        Documentation = [ "man:systemd.special(7)" ];
        BindsTo = [ "graphical-session.target" ];
        Wants = [
          "graphical-session-pre.target"
        ]
        ++ lib.optional cfg.systemd.enableXdgAutostart "xdg-desktop-autostart.target";
        After = [ "graphical-session-pre.target" ];
        Before = lib.mkIf cfg.systemd.enableXdgAutostart [ "xdg-desktop-autostart.target" ];
      };
    };
  };
}
