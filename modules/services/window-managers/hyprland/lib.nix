{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrNames
    concatMapStrings
    filter
    filterAttrs
    isString
    optionalString
    replaceStrings
    sort
    ;

  toLua = lib.generators.toLua { };

  systemdVariables = lib.concatStringsSep " " config.systemd.variables;
  systemdExtraCommands = lib.concatStringsSep " " (map (f: "&& ${f}") config.systemd.extraCommands);
  systemdActivationCommand = "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd ${systemdVariables} ${systemdExtraCommands}";

  pluginPath =
    entry: if lib.types.package.check entry then "${entry}/lib/lib${entry.pname}.so" else entry;

  renderSection =
    name: text:
    optionalString (text != "") ''
      -- ${name}
      ${text}
    '';

  luaModuleName = name: replaceStrings [ "/" ] [ "." ] (lib.removeSuffix ".lua" name);

  luaModulePath = name: replaceStrings [ "." ] [ "/" ] (luaModuleName name);

  luaFileName = name: "${luaModulePath name}.lua";

  # `_args` renders attrsets as Lua multi-argument calls instead of tables.
  renderLuaArgs =
    value:
    if lib.isAttrs value && value ? _args then
      lib.concatMapStringsSep ", " toLua value._args
    else
      toLua value;

  isLuaLocal = value: lib.isAttrs value && value ? _var;

  luaLocalName = name: value: value.name or name;

  hasNonStringValue = values: lib.any (value: !isString value) values;

  isPathLike = value: lib.isPath value || lib.isStorePath value;
in
{
  inherit
    luaFileName
    luaModuleName
    luaModulePath
    ;

  hyprlangConfig =
    {
      reloadConfig,
    }:
    let
      importantPrefixes = config.importantPrefixes ++ lib.optional config.sourceFirst "source";

      pluginsToHyprconf =
        plugins:
        lib.hm.generators.toHyprconf {
          attrs = {
            "exec-once" = map (entry: "hyprctl plugin load ${pluginPath entry}") plugins;
          };
          inherit importantPrefixes;
        };

      # Hyprlang submaps render only string entries.
      hyprlangSubmapSettings =
        settings: filterAttrs (_: values: values != [ ]) (lib.mapAttrs (_: filter isString) settings);

      hyprlangSubmaps = filterAttrs (
        _: submap: hyprlangSubmapSettings submap.settings != { }
      ) config.submaps;

      mkSubMap = name: attrs: ''
        submap = ${name}${optionalString (attrs.onDispatch != "") ", ${attrs.onDispatch}"}
        ${
          lib.hm.generators.toHyprconf {
            attrs = hyprlangSubmapSettings attrs.settings;
            indentLevel = 0;
          }
        }submap = reset
      '';

      submapsToHyprConf = lib.concatMapAttrsStringSep "\n" mkSubMap hyprlangSubmaps;

      shouldGenerate =
        config.systemd.enable
        || config.extraConfig != ""
        || config.settings != { }
        || config.plugins != [ ]
        || hyprlangSubmaps != { };
    in
    lib.mkIf shouldGenerate {
      text =
        optionalString config.systemd.enable ''
          exec-once = ${systemdActivationCommand}
        ''
        + optionalString (config.plugins != [ ]) (pluginsToHyprconf config.plugins)
        + optionalString (config.settings != { }) (
          lib.hm.generators.toHyprconf {
            attrs = config.settings;
            inherit importantPrefixes;
          }
        )
        + optionalString (hyprlangSubmaps != { }) submapsToHyprConf
        + optionalString (config.extraConfig != "") config.extraConfig;

      onChange = lib.mkIf (config.package != null) reloadConfig;
    };

  luaConfig =
    {
      reloadConfig,
      xdgConfigHome,
    }:
    let
      renderPluginLoad = renderSection "plugins" (
        concatMapStrings (entry: "hl.plugin.load(${toLua (pluginPath entry)})\n") config.plugins
      );

      startupCommands = lib.optionals config.systemd.enable [ systemdActivationCommand ];

      renderSettings =
        let
          names = sort lib.lessThan (attrNames config.settings);
          luaLocalNames = filter (name: isLuaLocal config.settings.${name}) names;
          settingNames = filter (name: !(builtins.elem name luaLocalNames)) names;
          importantNames = lib.unique (
            lib.concatMap (
              prefix: filter (name: lib.hasPrefix prefix name) settingNames
            ) config.importantPrefixes
          );
          orderedNames = importantNames ++ filter (name: !(builtins.elem name importantNames)) settingNames;
          renderLocal =
            name:
            let
              value = config.settings.${name};
            in
            "local ${luaLocalName name value} = ${renderLuaArgs value._var}\n";
          renderCall = name: value: "hl.${name}(${renderLuaArgs value})\n";
          renderCalls =
            name: value: concatMapStrings (renderCall name) (if lib.isList value then value else [ value ]);
        in
        optionalString (luaLocalNames != [ ]) (
          renderSection "settings.locals" (concatMapStrings renderLocal luaLocalNames)
        )
        + concatMapStrings (
          name: renderSection "settings.${name}" (renderCalls name config.settings.${name})
        ) orderedNames;

      renderStartHook =
        if startupCommands == [ ] then
          ""
        else
          renderSection "startup" ''
            hl.on("hyprland.start", function()
            ${concatMapStrings (command: "  hl.exec_cmd(${toLua command})\n") startupCommands}end)
          '';

      renderLuaFiles =
        let
          autoloadFiles = filterAttrs (_: file: file.autoLoad) config.extraLuaFiles;
          names = sort lib.lessThan (attrNames autoloadFiles);
        in
        if names == [ ] then
          ""
        else
          renderSection "extraLuaFiles" (
            ''
              local hm_xdg_config_home = os.getenv("XDG_CONFIG_HOME") or ${toLua xdgConfigHome}
              package.path = hm_xdg_config_home .. "/hypr/?.lua;" .. hm_xdg_config_home .. "/hypr/?/init.lua;" .. package.path
            ''
            + lib.concatMapStringsSep "\n" (name: "require(${toLua (luaModuleName name)})") names
          );

      # Lua submaps render structured entries and skip Hyprlang strings.
      luaSubmaps = filterAttrs (
        _: submap: lib.any hasNonStringValue (lib.attrValues submap.settings)
      ) config.submaps;

      renderSubmaps =
        let
          renderLuaArg = value: replaceStrings [ "\n" ] [ "\n  " ] (renderLuaArgs value);
          renderCall = name: value: "  hl.${name}(${renderLuaArg value})\n";
          renderCalls =
            name: values: concatMapStrings (renderCall name) (filter (value: !isString value) values);
          renderSubmap =
            name: submap:
            renderSection "submaps.${name}" (
              "hl.define_submap(${toLua name}"
              + optionalString (submap.onDispatch != "") ", ${toLua submap.onDispatch}"
              + ", function()\n"
              + concatMapStrings (settingName: renderCalls settingName submap.settings.${settingName}) (
                sort lib.lessThan (attrNames submap.settings)
              )
              + "end)\n"
            );
          names = sort lib.lessThan (attrNames luaSubmaps);
        in
        concatMapStrings (name: renderSubmap name luaSubmaps.${name}) names;

      shouldGenerate =
        config.systemd.enable
        || config.extraConfig != ""
        || config.extraLuaFiles != { }
        || config.settings != { }
        || config.plugins != [ ]
        || luaSubmaps != { };
    in
    lib.mkIf shouldGenerate {
      text = ''
        -- Generated by Home Manager.
        -- See https://wiki.hypr.land/Configuring/Start/

      ''
      + renderPluginLoad
      + renderLuaFiles
      + renderSettings
      + renderSubmaps
      + renderStartHook
      + renderSection "extraConfig" config.extraConfig;

      onChange = lib.mkIf (config.package != null) reloadConfig;
    };

  extraLuaFiles = lib.mapAttrs' (
    name: file:
    lib.nameValuePair "hypr/${luaFileName name}" (
      if isPathLike file.content then { source = file.content; } else { text = file.content; }
    )
  ) config.extraLuaFiles;
}
