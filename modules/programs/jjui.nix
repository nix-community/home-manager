{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOption;

  cfg = config.programs.jjui;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = with lib.maintainers; [
    adda
    khaneliman
  ];

  options.programs.jjui = {
    enable = lib.mkEnableOption "jjui - A terminal user interface for jujutsu";

    package = lib.mkPackageOption pkgs "jjui" { nullable = true; };

    configDir = mkOption {
      type = lib.types.str;
      default = "${config.xdg.configHome}/jjui";
      defaultText = lib.literalExpression "\${config.xdg.configHome}/jjui";
      example = lib.literalExpression "\${config.home.homeDirectory}/.jjui";
      description = ''
        The directory to contain jjui configuration files.

        Home Manager does not set {env}`JJUI_CONFIG_DIR` when this is
        {file}`$XDG_CONFIG_HOME/jjui` on Linux with {option}`xdg.enable`,
        or {file}`$HOME/.config/jjui` otherwise, so jjui can load
        repository-specific configuration.

        For other directories, Home Manager sets {env}`JJUI_CONFIG_DIR`
        so jjui can find the configuration. This disables loading
        repository-specific {file}`.jjui/config.toml` and
        {file}`.jjui/config.lua` files.

        On Darwin, Home Manager also sets {env}`JJUI_CONFIG_DIR` when
        {option}`configLua` or {option}`plugins` is configured without
        {option}`settings`, even at the default path. This prevents another
        directory's {file}`config.toml` from redirecting jjui away from the
        managed Lua files. Custom {option}`xdg.configHome` paths also require
        the variable because jjui's automatic directory selection depends
        on existing {file}`config.toml` files.
      '';
    };

    settings = mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = {
        revisions = {
          template = "builtin_log_compact";
          revset = "";
        };
      };
      description = ''
        Options to add to the {file}`(config.programs.jjui.configDir)/config.toml` file. See
        <https://idursun.github.io/jjui/customization/config-toml/>
        for options.
      '';
    };

    configLua = mkOption {
      type = with lib.types; nullOr (either path lines);
      default = null;
      example = /* lua */ ''
        local foo = require("plugins.foo")
        local bar = require("plugins.bar")

        function setup(config)
          foo.setup(config)
          bar.setup("#5B8DEF", config)

          config.action("show diff in diffnav", function()
            local change_id = context.change_id()
            if not change_id or change_id == "" then
              flash({ text = "No revision selected", error = true })
              return
            end

            exec_shell(string.format("jj diff -r %q --git --color always | diffnav", change_id))
          end, { desc = "show diff in diffnav", key = "ctrl+d", scope = "revisions" })
        end
      '';
      description = ''
        The content of the {file}`(config.programs.jjui.configDir)/config.lua` file, set either by specifying a path
        to a Lua file or by providing a multi-line Lua string.

        See <https://idursun.github.io/jjui/customization/config-lua/> for documentation on Lua support.

        Use the option {option}`plugins` to configure Lua plugins imported here.
      '';
    };

    plugins = mkOption {
      type =
        with lib.types;
        attrsOf (oneOf [
          path
          lines
        ]);
      default = { };
      description = ''
        Lua plugins, one per attribute.
        The <name> attribute will become the plugin name, and the <value> attribute is a path to a Lua file or a multi-line Lua string.
        Each attribute will be linked to {file}`(config.programs.jjui.configDir)/plugins/<name>.lua` with <value> content.

        See <https://idursun.github.io/jjui/customization/config-lua/>
        for documentation on Lua support.

        Remember to import the defined plugins in the {option}`configLua` option.
      '';
      example = lib.literalExpression ''
        {
          foo = ./foo.lua;
          bar = /* lua */ '\'
            local M = {}

            function M.setup(primary, config)
              config.ui = config.ui or {}
              config.ui.colors = config.ui.colors or {}

              config.ui.colors.title = { fg = primary, bold = true }
            end

            return M
          '\';
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = mkIf (cfg.package != null) [ cfg.package ];

      file =
        lib.mapAttrs' (name: content: {
          name = "${cfg.configDir}/plugins/${name}.lua";
          value =
            if builtins.isPath content || lib.isStorePath content then
              { source = content; }
            else
              { text = content; };
        }) cfg.plugins
        // {
          "${cfg.configDir}/config.toml" = mkIf (cfg.settings != { }) {
            source = tomlFormat.generate "jjui-config" cfg.settings;
          };

          "${cfg.configDir}/config.lua" = mkIf (cfg.configLua != null) (
            if builtins.isPath cfg.configLua || lib.isStorePath cfg.configLua then
              { source = cfg.configLua; }
            else
              { text = cfg.configLua; }
          );
        };

      sessionVariables =
        let
          autoConfigDir =
            if pkgs.stdenv.hostPlatform.isLinux && config.xdg.enable then
              "${config.xdg.configHome}/jjui"
            else
              "${config.home.homeDirectory}/.config/jjui";
        in
        mkIf
          (
            cfg.configDir != autoConfigDir
            || (
              pkgs.stdenv.hostPlatform.isDarwin
              && cfg.settings == { }
              && (cfg.configLua != null || cfg.plugins != { })
            )
          )
          {
            JJUI_CONFIG_DIR = cfg.configDir;
          };
    };
  };
}
