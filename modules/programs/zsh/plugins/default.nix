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
          lib.concatStrings (
            map (plugin: ''
              path+="${pluginsDir}/${plugin.name}"
              fpath+="${pluginsDir}/${plugin.name}"
              ${
                (lib.optionalString (plugin.completions != [ ]) ''
                  fpath+=(${
                    lib.concatMapStringsSep " " (
                      completion: "\"${pluginsDir}/${plugin.name}/${completion}\""
                    ) plugin.completions
                  })
                '')
              }
            '') cfg.plugins
          )
        ))

        (lib.mkOrder 900 (
          lib.concatStrings (
            map (plugin: ''
              if [[ -f "${pluginsDir}/${plugin.name}/${plugin.file}" ]]; then
                source "${pluginsDir}/${plugin.name}/${plugin.file}"
              fi
            '') cfg.plugins
          )
        ))
      ];
    };
  };
}
