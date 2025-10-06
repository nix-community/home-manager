{
  config,
  lib,
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

            completions = mkOption {
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
            completions = [ "share/zsh/site-functions" ];
          }
          ]
        '';
        description = "Plugins to source in {file}`.zshrc`.";
      };
    };

  config = lib.mkIf (cfg.plugins != [ ]) {
    home.file = lib.mkIf cfg.enable (
      lib.foldl' (a: b: a // b) { } (
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
            completionPaths = lib.flatten (
              map (plugin: map (completion: "${plugin.name}/${completion}") plugin.completions) cfg.plugins
            );
          in
          ''
            # Add plugin directories to PATH and fpath
            ${lib.hm.zsh.define "plugin_dirs" pluginNames}
            for plugin_dir in "''${plugin_dirs[@]}"; do
              path+="${pluginsDir}/$plugin_dir"
              fpath+="${pluginsDir}/$plugin_dir"
            done
            unset plugin_dir plugin_dirs
            ${lib.optionalString (completionPaths != [ ]) ''
              # Add completion paths to fpath
              ${lib.hm.zsh.define "completion_paths" completionPaths}
              for completion_path in "''${completion_paths[@]}"; do
                fpath+="${pluginsDir}/$completion_path"
              done
              unset completion_path completion_paths
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
