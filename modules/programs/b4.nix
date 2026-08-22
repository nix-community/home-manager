{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.b4;
in
{
  meta.maintainers = [ lib.maintainers.fzakaria ];

  options.programs.b4 = {
    enable = lib.mkEnableOption "b4, a tool for kernel-style patch/email review workflows";

    package = lib.mkPackageOption pkgs "b4" { };

    settings = lib.mkOption {
      type =
        with lib.types;
        attrsOf (oneOf [
          bool
          int
          str
          (listOf str)
        ]);
      default = { };
      example = lib.literalExpression ''
        {
          attestation-policy = "hardfail";
          midmask = "https://lore.kernel.org/all/%s";
        }
      '';
      description = ''
        Settings written to git-config's `[b4]` section, b4's only configuration
        source. Written via {option}`programs.git.settings`, so a non-empty value
        requires {option}`programs.git.enable`.

        See <https://b4.docs.kernel.org/en/latest/config.html> for the keys.
      '';
    };

    agentReview = {
      enable = lib.mkEnableOption ''
        the AI reviewer behind the `a` key in the `b4 review` TUI, by writing the
        `review-agent-command` and `review-agent-prompt-path` `[b4]` settings
      '';

      command = lib.mkOption {
        type = lib.types.str;
        default =
          "${lib.getExe pkgs.claude-code}"
          + " --add-dir .git"
          + " --add-dir ${lib.escapeShellArg (dirOf cfg.agentReview.instructions)}"
          + " --allowedTools 'Bash(git:*) Read Glob Grep Write(.git/b4-review/**) Edit(.git/b4-review/**)'"
          + " --";
        defaultText = lib.literalMD "A Claude Code invocation (`pkgs.claude-code`)";
        example = lib.literalExpression ''"''${lib.getExe pkgs.aider-chat} --message"'';
        description = ''
          The command b4 runs for the agent action. It is POSIX-shlex-split, gets
          a final argument pointing at
          {option}`programs.b4.agentReview.instructions`, and runs with the
          repository top as its working directory, so relative `.git` paths
          resolve per-repo.
        '';
      };

      instructions = lib.mkOption {
        type = with lib.types; either str path;
        # misc/ is absent from the PyPI sdist the package builds from, so the b4
        # package exposes the matching git checkout as `passthru.src-misc`.
        default = "${cfg.package.src-misc}/misc/agent-reviewer.md";
        defaultText = lib.literalMD "b4's shipped `misc/agent-reviewer.md`";
        example = lib.literalExpression "./my-agent-reviewer.md";
        description = ''
          Instructions telling the agent how to write review files under
          {file}`.git/b4-review/`. Written to `review-agent-prompt-path` as an
          absolute path, so it applies to every repository.
        '';
      };
    };

    vimSyntax = lib.mkOption {
      type = lib.types.bool;
      default = config.programs.vim.enable || config.programs.neovim.enable;
      defaultText = lib.literalExpression "config.programs.vim.enable || config.programs.neovim.enable";
      description = ''
        Whether to add b4's review-editor syntax highlighting, which activates for
        {file}`*.b4-review.eml` buffers, to
        {option}`programs.vim`/{option}`programs.neovim`. Editors managed outside
        home-manager can instead put {option}`programs.b4.vimPlugin` on their
        runtimepath.
      '';
    };

    emacsSyntax = lib.mkOption {
      type = lib.types.bool;
      default = config.programs.emacs.enable;
      defaultText = lib.literalExpression "config.programs.emacs.enable";
      description = ''
        Whether to add b4's `b4-review-mode`, which autoloads for
        {file}`*.b4-review.eml` files, to {option}`programs.emacs`. Editors managed
        outside home-manager can instead consume
        {option}`programs.b4.emacsPackage`.
      '';
    };

    vimPlugin = lib.mkPackageOption pkgs [ "vimPlugins" "b4-review-vim" ] {
      extraDescription = ''
        b4's Vim review-editor files as a runtimepath plugin, for adding to
        e.g. {option}`programs.neovim.plugins`.
      '';
    };

    emacsPackage = lib.mkOption {
      type = lib.types.functionTo lib.types.package;
      default = epkgs: epkgs.b4-review-mode;
      defaultText = lib.literalExpression "epkgs: epkgs.b4-review-mode";
      description = ''
        Selector picking b4's `b4-review-mode.el` out of an Emacs package set, for
        adding to e.g. {option}`programs.emacs.extraPackages`.
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        home.packages = [ cfg.package ];

        assertions = [
          {
            assertion = cfg.settings == { } || config.programs.git.enable;
            message = ''
              programs.b4.settings has [b4] git-config to write, so
              programs.git.enable must be true.
            '';
          }
        ];
      }

      (lib.mkIf (cfg.settings != { }) {
        programs.git.settings.b4 = cfg.settings;
      })

      # mkDefault leaves both keys overridable from `settings`.
      (lib.mkIf cfg.agentReview.enable {
        programs.b4.settings = {
          review-agent-command = lib.mkDefault cfg.agentReview.command;
          review-agent-prompt-path = lib.mkDefault "${cfg.agentReview.instructions}";
        };
      })

      # A plugins/packages list on a disabled editor is inert, so both branches
      # are safe even when only one editor is enabled.
      (lib.mkIf cfg.vimSyntax {
        programs.neovim.plugins = [ cfg.vimPlugin ];
        programs.vim.plugins = [ cfg.vimPlugin ];
      })

      (lib.mkIf cfg.emacsSyntax {
        programs.emacs.extraPackages = epkgs: [ (cfg.emacsPackage epkgs) ];
      })
    ]
  );
}
