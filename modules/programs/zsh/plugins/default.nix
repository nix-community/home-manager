{
  config,
  lib,
  options,
  ...
}:
let
  inherit (lib) mkOption types;

  cfg = config.programs.zsh;

  inherit (import ../lib.nix { inherit config lib; }) pluginsDir;
in
{
  imports = [
    ./oh-my-zsh.nix
    ./prezto.nix
    ./zprof.nix
    ./zsh-abbr.nix
  ];

  options =
    let
      pluginModule = types.submodule (
        { config, ... }:
        {
          imports = [
            (lib.mkRenamedOptionModule [ "completions" ] [ "functions" ])
          ];

          options = {
            src = mkOption {
              type = types.path;
              description = ''
                Path to the plugin folder.

                Will be added to {env}`fpath` and {env}`PATH`.
              '';
            };

            name = mkOption {
              type = types.str;
              description = ''
                The name of the plugin.
              '';
            };

            file = mkOption {
              type = types.str;
              description = ''
                The plugin script to source.
                Required if the script name does not match {file}`name.plugin.zsh`
                using the plugin {option}`name` from the plugin {option}`src`.
              '';
            };

            functions = mkOption {
              default = [ ];
              type = types.listOf types.str;
              description = "Paths of additional functions to add to {env}`fpath`.";
            };
          };

          config.file = lib.mkDefault "${config.name}.plugin.zsh";
        }
      );
    in
    {
      programs.zsh.plugins = mkOption {
        type = types.listOf pluginModule;
        default = [ ];
        example = lib.literalExpression ''
          [
            {
              name = "enhancd";
              file = "init.sh";
              src = pkgs.fetchFromGitHub {
                owner = "b4b4r07";
                repo = "enhancd";
                rev = "v2.2.1";
                sha256 = "0iqa9j09fwm6nj5rpip87x3hnvbbz9w9ajgm6wkrd5fls8fn8i5g";
              };
            }
          {
            name = "wd";
            src = pkgs.zsh-wd;
            file = "share/wd/wd.plugin.zsh";
            functions = [ "share/zsh/site-functions" ];
          }
          ]
        '';
        description = "Plugins to source in {file}`.zshrc`.";
      };
    };

  config = lib.mkIf (cfg.plugins != [ ]) {
    warnings = lib.concatMap (
      definition:
      lib.optionals (builtins.isList definition.value) (
        lib.concatMap (
          value:
          lib.optional (builtins.isAttrs value && value ? completions)
            "The option `programs.zsh.plugins.*.completions' defined in ${
              lib.showFiles [ definition.file ]
            } has been renamed to `programs.zsh.plugins.*.functions'."
        ) definition.value
      )
    ) options.programs.zsh.plugins.definitionsWithLocations;

    home.file = lib.mkIf cfg.enable (
      lib.mergeAttrsList (
        map (plugin: { "${pluginsDir}/${plugin.name}".source = plugin.src; }) cfg.plugins
      )
    );

    programs.zsh = {
      # Many plugins require compinit to be called
      # but allow the user to opt out.
      enableCompletion = lib.mkDefault true;

      initContent = lib.mkMerge [
        (lib.mkOrder 560 (
          let
            pluginNames = map (plugin: plugin.name) cfg.plugins;
            functionPaths = lib.flatten (
              map (plugin: map (function: "${plugin.name}/${function}") plugin.functions) cfg.plugins
            );
          in
          ''
            # Add plugin directories to PATH and fpath
            ${lib.hm.zsh.define "plugin_dirs" pluginNames}
            for plugin_dir in "''${plugin_dirs[@]}"; do
              path+="${pluginsDir}/$plugin_dir"
              fpath+="${pluginsDir}/$plugin_dir"
              for plugin_fpath_dir in \
                "$plugin_dir/share/zsh/plugins/$plugin_dir" \
                "$plugin_dir/share/zsh/site-functions" \
                "$plugin_dir/share/zsh/vendor-completions"; do
                [[ -d "${pluginsDir}/$plugin_fpath_dir" ]] && fpath+="${pluginsDir}/$plugin_fpath_dir"
              done
            done
            unset plugin_dir plugin_dirs plugin_fpath_dir
            ${lib.optionalString (functionPaths != [ ]) ''
              # Add additional function paths to fpath
              ${lib.hm.zsh.define "function_paths" functionPaths}
              for function_path in "''${function_paths[@]}"; do
                fpath+="${pluginsDir}/$function_path"
              done
              unset function_path function_paths
            ''}
          ''
        ))

        (lib.mkOrder 900 (
          let
            pluginPaths = map (plugin: "${plugin.name}/${plugin.file}") cfg.plugins;
          in
          ''
            # Source plugins
            ${lib.hm.zsh.define "plugins" pluginPaths}
            for plugin in "''${plugins[@]}"; do
              [[ -f "${pluginsDir}/$plugin" ]] && source "${pluginsDir}/$plugin"
            done
            unset plugin plugins
          ''
        ))
      ];
    };
  };
}
