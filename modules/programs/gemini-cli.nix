{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.gemini-cli;

  jsonFormat = pkgs.formats.json { };
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = [ lib.hm.maintainers.rrvsh ];

  options.programs.gemini-cli = {
    enable = lib.mkEnableOption "gemini-cli";

    package = lib.mkPackageOption pkgs "gemini-cli" { nullable = true; };

    settings = lib.mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = lib.literalExpression ''
        {
          "theme": "Default",
          "vimMode": true,
          "preferredEditor": "nvim",
          "autoAccept": true
        }
      '';
      description = "JSON config for gemini-cli";
    };

    commands =
      let
        commandType = lib.types.submodule {
          freeformType = lib.types.str;
          options = {
            prompt = lib.mkOption {
              type = lib.types.str;
              description = ''
                The prompt that will be sent to the Gemini model when the command is executed.
                This can be a single-line or multi-line string.
                The special placeholder {{args}} will be replaced with the text the user typed after the command name.
              '';
            };
            description = lib.mkOption {
              type = lib.types.str;
              description = ''
                A brief, one-line description of what the command does.
                This text will be displayed next to your command in the /help menu.
                If you omit this field, a generic description will be generated from the filename.
              '';
            };
          };
        };
      in
      lib.mkOption {
        type = lib.types.attrsOf commandType;
        default = { };
        description = ''
          An attribute set of custom commands that will be globally available.
          The name of the attribute set will be the name of each command.
          You may use subdirectories to create namespaced commands, such as `git/fix` becoming `/git:fix`.
          See https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/commands.md#custom-commands for more information.
        '';
        example = lib.literalExpression ''
          changelog = {
            prompt =
              '''
              Your task is to parse the `<version>`, `<change_type>`, and `<message>` from their input and use the `write_file` tool to correctly update the `CHANGELOG.md` file.
              ''';
            description = "Adds a new entry to the project's CHANGELOG.md file.";
          };
          "git/fix" = { # Becomes /git:fix
            prompt = "Please analyze the staged git changes and provide a code fix for the issue described here: {{args}}.";
            description = "Generates a fix for a given GitHub issue.";
          };
        '';
      };

    defaultModel = lib.mkOption {
      type = lib.types.str;
      default = "gemini-2.5-pro";
      example = "gemini-2.5-flash";
      description = ''
        The default model to use for the CLI.
        Will be set as $GEMINI_MODEL.
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        home = {
          packages = lib.mkIf (cfg.package != null) [ cfg.package ];
          file.".gemini/settings.json" = lib.mkIf (cfg.settings != { }) {
            source = jsonFormat.generate "gemini-cli-settings.json" cfg.settings;
          };
          sessionVariables.GEMINI_MODEL = cfg.defaultModel;
        };
      }
      {
        home.file = lib.mapAttrs' (
          n: v:
          lib.nameValuePair ".gemini/commands/${n}.toml" {
            source = tomlFormat.generate "gemini-cli-command-${n}.toml" {
              inherit (v) description prompt;
            };
          }
        ) cfg.commands;
      }
    ]
  );
}
