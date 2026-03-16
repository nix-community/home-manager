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
  meta.maintainers = [ lib.maintainers.rrvsh ];

  options.programs.gemini-cli = {
    enable = lib.mkEnableOption "gemini-cli";

    package = lib.mkPackageOption pkgs "gemini-cli" { nullable = true; };

    settings = lib.mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = {
        ui.theme = "Default";
        general = {
          vimMode = true;
          preferredEditor = "nvim";
          previewFeatures = true;
        };
        ide.enabled = true;
        privacy.usageStatisticsEnabled = false;
        tools.autoAccept = false;
        context.loadMemoryFromIncludeDirectories = true;
      };
      description = ''
        Configuration settings for gemini-cli. All the available options can be found here:
        <https://geminicli.com/docs/get-started/configuration/#available-settings-in-settingsjson>
      '';
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
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "gemini-2.5-flash";
      description = ''
        The default model to use for the CLI.
        Will be set as $GEMINI_MODEL when configured.
      '';
    };

    context = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path);
      default = { };
      example = lib.literalExpression ''
        {
          GEMINI = '''
            # Global Context

            You are a helpful AI assistant for software development.

            ## Coding Standards

            - Follow consistent code style
            - Write clear comments
            - Test your changes
          ''';

          AGENTS = ./path/to/agents.md;

          CONTEXT = '''
            Additional context instructions here.
          ''';
        }
      '';
      description = ''
        An attribute set of context files to create in `~/.gemini/`.
        The attribute name becomes the filename with `.md` extension automatically added.
        The value is either inline content or a path to a file.

        Note: You can customize which context file names gemini-cli looks for by setting
        `settings.context.fileName`. For example:
        ```nix
        settings = {
          context.fileName = ["AGENTS.md", "CONTEXT.md", "GEMINI.md"];
        };
        ```
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        home = {
          packages = lib.mkIf (cfg.package != null) [ cfg.package ];
          activation = lib.mkIf (cfg.settings != { }) {
            copyGeminiCLIConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              configFile=${config.home.homeDirectory}/.gemini/settings.json
              generatedConfig=${jsonFormat.generate "gemini-cli-settings" cfg.settings}

              if [[ -L "$configFile" ]]; then
                verboseEcho "Unlinking old gemini-cli's config file..."
                unlink "$configFile"
              fi

              if [[ -f "$configFile" ]]; then
                verboseEcho "Patching existing gemini-cli's config file..."
                tmpFile=$(mktemp)
                ${lib.getExe pkgs.jq} '.[0] * .[1]' "$configFile" "$generatedConfig" > "$tmpFile"
                mv "$tmpFile" "$configFile"
              else
                verboseEcho "Copying gemini-cli's config file..."
                cp "$generatedConfig" "$configFile"
              fi

              chmod 600 "$configFile"
            '';
          };
          sessionVariables = lib.mkIf (cfg.defaultModel != null) {
            GEMINI_MODEL = cfg.defaultModel;
          };
        };
      }
      {
        home.file = lib.mapAttrs' (
          n: v: lib.nameValuePair ".gemini/${n}.md" (if lib.isPath v then { source = v; } else { text = v; })
        ) cfg.context;
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
