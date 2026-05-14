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

  luaModuleName = name: lib.replaceStrings [ "/" ] [ "." ] (lib.removeSuffix ".lua" name);

  luaFileName = name: "${lib.replaceStrings [ "." ] [ "/" ] (luaModuleName name)}.lua";

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
  meta.maintainers = with lib.maintainers; [
    fufexan
    khaneliman
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
        Attribute values with `_var` generate a Lua local variable instead of
        an `hl.<name>(...)` call. If no `name` is set, the attribute name is
        used as the Lua variable name.
        Values created with `lib.generators.mkLuaInline` are rendered as raw
        Lua expressions.

      '';
      example = lib.literalExpression ''
        {
          mod = {
            _var = "SUPER";
          };

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
                (lib.generators.mkLuaInline "mod .. \" + Q\"")
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

    extraLuaFiles = lib.mkOption {
      type =
        with lib.types;
        attrsOf (
          coercedTo (either path lines)
            (content: {
              inherit content;
              autoLoad = true;
            })
            (submodule {
              options = {
                content = lib.mkOption {
                  type = either path lines;
                  description = ''
                    Lua file content, set either by specifying a path to a Lua
                    file or by providing a multi-line Lua string.
                  '';
                };

                autoLoad = lib.mkOption {
                  type = bool;
                  default = true;
                  description = ''
                    Whether to generate a `require(...)` call for this file in
                    {file}`$XDG_CONFIG_HOME/hypr/hyprland.lua`.
                  '';
                };
              };
            })
        );
      default = { };
      description = ''
        Extra Lua files written under {file}`$XDG_CONFIG_HOME/hypr`.

        Attribute names are used as Lua module names and converted to file
        names with a {file}`.lua` suffix added when missing. For example,
        `bindings` writes
        {file}`$XDG_CONFIG_HOME/hypr/bindings.lua`, while
        `lib.helpers` writes {file}`$XDG_CONFIG_HOME/hypr/lib/helpers.lua`.

        Files with {option}`autoLoad` enabled generate `require(...)` calls in
        {file}`$XDG_CONFIG_HOME/hypr/hyprland.lua` after adding the Hypr config
        directory to Lua's `package.path`. Use {option}`autoLoad = false` for
        helper modules that are imported by other Lua files.

        This option only affects generated files when
        {option}`wayland.windowManager.hyprland.configType` is `"lua"`.
      '';
      example = lib.literalExpression ''
        {
          "00-vars" = '\'
            local M = {}
            M.mainMod = "SUPER"
            return M
          '\';

          "bindings" = {
            content = ./bindings.lua;
            autoLoad = true;
          };

          "lib.helpers" = {
            content = ./helpers.lua;
            autoLoad = false;
          };
        }
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
      {
        assertion = !builtins.elem "hyprland.lua" (map luaFileName (lib.attrNames cfg.extraLuaFiles));
        message = "wayland.windowManager.hyprland.extraLuaFiles cannot define hyprland.lua because it is generated by the Hyprland module.";
      }
      {
        assertion =
          let
            targets = map luaFileName (lib.attrNames cfg.extraLuaFiles);
          in
          lib.length targets == lib.length (lib.unique targets);
        message = "wayland.windowManager.hyprland.extraLuaFiles contains entries that resolve to the same Lua file path.";
      }
    ];

    warnings =
      let
        inconsistent =
          (cfg.systemd.enable || cfg.plugins != [ ])
          && cfg.extraConfig == ""
          && cfg.extraLuaFiles == { }
          && cfg.settings == { }
          && cfg.submaps == { };
        warning = "You have enabled hyprland.systemd.enable or listed plugins in hyprland.plugins but do not have any configuration in hyprland.settings, hyprland.extraConfig, hyprland.extraLuaFiles or hyprland.submaps. This is almost certainly a mistake.";

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
        "hypr/.luarc.json" = lib.mkIf (cfg.configType == "lua" && cfg.finalPackage != null) {
          text = builtins.toJSON {
            workspace.library = [ "${cfg.finalPackage}/share/hypr/stubs" ];
            diagnostics.globals = [ "hl" ];
          };
        };
      }
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
                luaLocalNames = builtins.filter (
                  name: lib.isAttrs cfg.settings.${name} && cfg.settings.${name} ? _var
                ) names;
                settingNames = builtins.filter (name: !(builtins.elem name luaLocalNames)) names;
                importantNames = lib.unique (
                  lib.concatMap (
                    prefix: builtins.filter (name: lib.hasPrefix prefix name) settingNames
                  ) cfg.importantPrefixes
                );
                orderedNames =
                  importantNames ++ builtins.filter (name: !(builtins.elem name importantNames)) settingNames;
                renderLocal =
                  name:
                  let
                    value = cfg.settings.${name};
                  in
                  "local ${value.name or name} = ${renderArgs value._var}\n";
                renderCall = name: value: "hl.${name}(${renderArgs value})\n";
                renderCalls =
                  name: value:
                  lib.concatMapStrings (renderCall name) (if builtins.isList value then value else [ value ]);
              in
              lib.optionalString (luaLocalNames != [ ]) (
                renderSection "settings.locals" (lib.concatMapStrings renderLocal luaLocalNames)
              )
              + lib.concatMapStrings (
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

            renderLuaFiles =
              let
                autoloadFiles = lib.filterAttrs (_: file: file.autoLoad) cfg.extraLuaFiles;
                names = lib.sort lib.lessThan (lib.attrNames autoloadFiles);
              in
              if names == [ ] then
                ""
              else
                renderSection "extraLuaFiles" (
                  ''
                    local hm_xdg_config_home = os.getenv("XDG_CONFIG_HOME") or ${toLua config.xdg.configHome}
                    package.path = hm_xdg_config_home .. "/hypr/?.lua;" .. hm_xdg_config_home .. "/hypr/?/init.lua;" .. package.path
                  ''
                  + lib.concatMapStringsSep "\n" (name: "require(${toLua (luaModuleName name)})") names
                );

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
              || cfg.extraLuaFiles != { }
              || cfg.settings != { }
              || cfg.plugins != [ ]
              || hasLuaSubmaps;
          in
          lib.mkIf shouldGenerate {
            text = ''
              -- Generated by Home Manager.
              -- See https://wiki.hypr.land/Configuring/Start/

            ''
            + renderLuaFiles
            + renderSettings
            + renderSubmaps
            + renderStartHook
            + renderSection "extraConfig" cfg.extraConfig;

            onChange = lib.mkIf (cfg.package != null) reloadConfig;
          }
        );
      }
      (lib.mkIf (cfg.configType == "lua") (
        lib.mapAttrs' (
          name: file:
          lib.nameValuePair "hypr/${luaFileName name}" (
            if builtins.isPath file.content || lib.isStorePath file.content then
              { source = file.content; }
            else
              { text = file.content; }
          )
        ) cfg.extraLuaFiles
      ))
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
