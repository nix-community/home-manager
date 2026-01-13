{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.programs.codex;

  tomlFormat = pkgs.formats.toml { };
  yamlFormat = pkgs.formats.yaml { };

  packageVersion = if cfg.package != null then lib.getVersion cfg.package else "0.2.0";
  isTomlConfig = lib.versionAtLeast packageVersion "0.2.0";
  settingsFormat = if isTomlConfig then tomlFormat else yamlFormat;
in
{
  meta.maintainers = [
    lib.maintainers.delafthi
  ];

  options.programs.codex = {
    enable = lib.mkEnableOption "Lightweight coding agent that runs in your terminal";

    package = lib.mkPackageOption pkgs "codex" { nullable = true; };

    settings = lib.mkOption {
      # NOTE: `yaml` type supports null, using `nullOr` for backwards compatibility period
      type = lib.types.nullOr tomlFormat.type;
      description = ''
        Configuration written to {file}`CODEX_HOME/config.toml` (0.2.0+)
        or {file}`~/.codex/config.yaml` (<0.2.0). Per default {env}`CODEX_HOME`
        defaults to ~/.codex.
        See <https://github.com/openai/codex/blob/main/codex-rs/config.md> for supported values.
      '';
      default = { };
      defaultText = lib.literalExpression "{ }";
      example = lib.literalExpression ''
        {
          model = "gemma3:latest";
          model_provider = "ollama";
          model_providers = {
            ollama = {
              name = "Ollama";
              baseURL = "http://localhost:11434/v1";
              envKey = "OLLAMA_API_KEY";
            };
          };
        }
      '';
    };
    custom-instructions = lib.mkOption {
      type = lib.types.lines;
      description = "Define custom guidance for the agents; this value is written to {file}~/.codex/AGENTS.md";
      default = "";
      example = lib.literalExpression ''
        '''
          - Always respond with emojis
          - Only use git commands when explicitly requested
        '''
      '';
    };

    skills = lib.mkOption {
      type = lib.types.either (lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path)) lib.types.path;
      default = { };
      description = ''
        Custom skills for Codex.

        This option can either be:
        - An attribute set defining skills
        - A path to a directory containing multiple skill folders

        If an attribute set is used, the attribute name becomes the skill directory name,
        and the value is either:
        - Inline content as a string (creates {file}`skills/<name>/SKILL.md`)
        - A path to a file (creates {file}`skills/<name>/SKILL.md`)
        - A path to a directory (creates {file}`skills/<name>/` with all files)

        If a path is used, it is expected to contain one folder per skill name, each
        containing a {file}`SKILL.md`. The directory is symlinked to {file}`skills/`.
      '';
      example = lib.literalExpression ''
        {
          pdf-processing = '''
            ---
            name: pdf-processing
            description: Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction.
            ---

            # PDF Processing

            ## Quick start

            Use pdfplumber to extract text from PDFs:

            ```python
            import pdfplumber

            with pdfplumber.open("document.pdf") as pdf:
                text = pdf.pages[0].extract_text()
            ```
          ''';
          data-analysis = ./skills/data-analysis;
        }
      '';
    };
  };

  config =
    let
      useXdgDirectories = (config.home.preferXdgDirectories && isTomlConfig);
      xdgConfigHome = lib.removePrefix config.home.homeDirectory config.xdg.configHome;
      configDir = if useXdgDirectories then "${xdgConfigHome}/codex" else ".codex";
      configFileName = if isTomlConfig then "config.toml" else "config.yaml";
    in
    mkIf cfg.enable {
      assertions = [
        {
          assertion = !lib.isPath cfg.skills || lib.pathIsDirectory cfg.skills;
          message = "`programs.codex.skills` must be a directory when set to a path";
        }
      ];

      home = {
        packages = mkIf (cfg.package != null) [ cfg.package ];
        file = {
          "${configDir}/${configFileName}" = lib.mkIf (cfg.settings != { }) {
            source = settingsFormat.generate "codex-config" cfg.settings;
          };
          "${configDir}/AGENTS.md" = lib.mkIf (cfg.custom-instructions != "") {
            text = cfg.custom-instructions;
          };
          "${configDir}/skills" = lib.mkIf (lib.isPath cfg.skills) {
            source = cfg.skills;
            recursive = true;
          };
        }
        // (lib.mapAttrs' (
          name: content:
          if lib.isPath content && lib.pathIsDirectory content then
            lib.nameValuePair "${configDir}/skills/${name}" {
              source = content;
              recursive = true;
            }
          else
            lib.nameValuePair "${configDir}/skills/${name}/SKILL.md" (
              if lib.isPath content then { source = content; } else { text = content; }
            )
        ) (if builtins.isAttrs cfg.skills then cfg.skills else { }));
        sessionVariables = mkIf useXdgDirectories {
          CODEX_HOME = "${config.xdg.configHome}/codex";
        };
      };
    };
}
