{
  appName,
  lib,
  moduleName,
  ...
}:
let
  inherit (lib) types;
  inherit (lib.options) literalExpression mkOption;
in
{
  _class = "homeManager.vscodeProfile";
  options = {

    userSettings = mkOption {
      type = with types; either path json;
      default = { };
      example = {
        "files.autoSave" = "off";
        "[nix]"."editor.tabSize" = 2;
      };
      description = ''
        Configuration written to ${appName}'s
        {file}`settings.json`.
        This can be a JSON object or a path to a custom JSON file.
      '';
    };

    userTasks = mkOption {
      type = with types; either path json;
      default = { };
      example = {
        version = "2.0.0";
        tasks = [
          {
            type = "shell";
            label = "Hello task";
            command = "hello";
          }
        ];
      };
      description = ''
        Configuration written to ${appName}'s
        {file}`tasks.json`.
        This can be a JSON object or a path to a custom JSON file.
      '';
    };

    enableMcpIntegration = mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to integrate the MCP servers config from
        {option}`programs.mcp.servers` into
        {option}`${moduleName}.userMcp`.

        Note: Settings defined in {option}`programs.mcp.servers` are merged
        with {option}`${moduleName}.userMcp`, with ${appName}
        settings taking precedence.
      '';
    };

    userMcp = mkOption {
      type = with types; either path json;
      default = { };
      example.servers.Github.url = "https://api.githubcopilot.com/mcp/";
      description = ''
        Configuration written to ${appName}'s
        {file}`mcp.json`.
        This can be a JSON object or a path to a custom JSON file.
      '';
    };

    keybindings = mkOption {
      type = types.either types.path (
        types.listOf (
          types.submodule {
            freeformType = types.json;
            options = {
              key = mkOption {
                type = types.str;
                example = "ctrl+c";
                description = "The key or key-combination to bind.";
              };

              command = mkOption {
                type = types.str;
                example = "editor.action.clipboardCopyAction";
                description = "The VS Code command to execute.";
              };

              when = mkOption {
                type = types.nullOr (types.str);
                default = null;
                example = "textInputFocus";
                description = "Optional context filter.";
              };

              # https://code.visualstudio.com/docs/getstarted/keybindings#_command-arguments
              args = mkOption {
                type = with types; nullOr json;
                default = null;
                example = {
                  direction = "up";
                };
                description = "Optional arguments for a command.";
              };
            };
          }
        )
      );
      default = [ ];
      example = [
        {
          key = "ctrl+c";
          command = "editor.action.clipboardCopyAction";
          when = "textInputFocus";
        }
      ];
      description = ''
        Keybindings written to ${appName}'s
        {file}`keybindings.json`.
        This can be a JSON object or a path to a custom JSON file.
      '';
    };

    extensions = mkOption {
      type = with types; listOf package;
      default = [ ];
      example = literalExpression "[ pkgs.vscode-extensions.bbenoist.nix ]";
      description = ''
        The extensions ${appName} should be started with.
      '';
    };

    languageSnippets = mkOption {
      type = types.json;
      default = { };
      example = {
        haskell = {
          fixme = {
            prefix = [ "fixme" ];
            body = [ "$LINE_COMMENT FIXME: $0" ];
            description = "Insert a FIXME remark";
          };
        };
      };
      description = "Defines user snippets for different languages.";
    };

    globalSnippets = mkOption {
      type = types.json;
      default = { };
      example = {
        fixme = {
          prefix = [ "fixme" ];
          body = [ "$LINE_COMMENT FIXME: $0" ];
          description = "Insert a FIXME remark";
        };
      };
      description = "Defines global user snippets.";
    };

    enableUpdateCheck = mkOption {
      type = with types; nullOr bool;
      default = null;
      description = ''
        Whether to enable update checks/notifications.
        Can only be set for the default profile, but
        it applies to all profiles.
      '';
    };

    enableExtensionUpdateCheck = mkOption {
      type = with types; nullOr bool;
      default = null;
      description = ''
        Whether to enable update notifications for extensions.
        Can only be set for the default profile, but
        it applies to all profiles.
      '';
    };

  };
}
