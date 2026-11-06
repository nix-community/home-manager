{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    literalExpression
    mkIf
    mkOption
    mkEnableOption
    types
    ;

  cfg = config.programs.xonsh;

  package =
    if cfg.extraPackages == null then
      cfg.package
    else
      cfg.package.override { inherit (cfg) extraPackages; };

  aliasesStr = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      k: v: "aliases[${lib.strings.escapeNixString k}] = ${builtins.toJSON v}"
    ) cfg.shellAliases
  );

  envVarsStr = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (k: v: "${"$"}${k} = ${builtins.toJSON v}") cfg.sessionVariables
  );

  xontribsStr =
    if cfg.xontribs == [ ] then "" else "xontrib load ${lib.concatStringsSep " " cfg.xontribs}";

  optionalBlock =
    comment: text:
    if lib.strings.stringLength (lib.strings.trim text) == 0 then "" else "# ${comment}\n${text}\n";

  rcText =
    let
      dollar = "$";
    in
    ''
      # ~/.config/xonsh/rc.xsh: DO NOT EDIT -- this file has been generated
      # automatically by home-manager.

      ${optionalBlock "Session variables" envVarsStr}
      ${optionalBlock "Xontribs" xontribsStr}
      ${optionalBlock "Aliases" aliasesStr}
      ${optionalBlock "Shell init" cfg.shellInit}
      ${lib.optionalString (lib.strings.trim cfg.loginShellInit != "") ''
        if ${dollar}XONSH_LOGIN:
            # Login shell initialisation
            ${lib.concatStringsSep "\n    " (lib.strings.splitString "\n" cfg.loginShellInit)}
      ''}
      ${lib.optionalString (lib.strings.trim cfg.interactiveShellInit != "") ''
        if ${dollar}XONSH_INTERACTIVE:
            # Interactive shell initialisation
            ${lib.concatStringsSep "\n    " (lib.strings.splitString "\n" cfg.interactiveShellInit)}
      ''}
      ${optionalBlock "Shell init last" cfg.shellInitLast}
      ${optionalBlock "Extra config" cfg.xonshrcExtra}
    '';

in
{
  meta.maintainers = with lib.maintainers; [ ZZBaron ];

  options.programs.xonsh = {
    enable = mkEnableOption "xonsh, a Python-powered shell";

    package = lib.mkPackageOption pkgs "xonsh" {
      extraDescription = ''
        When {option}`programs.xonsh.extraPackages` is set, this package will
        be overridden via its `extraPackages` argument, mirroring the NixOS
        `programs.xonsh` module behaviour.
      '';
    };

    extraPackages = mkOption {
      type = types.nullOr (
        types.coercedTo (types.listOf types.package) (v: (_: v)) (
          types.functionTo (types.listOf types.package)
        )
      );
      default = null;
      defaultText = literalExpression "null";
      example = literalExpression ''
        ps: with ps; [ numpy xonsh.xontribs.xontrib-vox ]
      '';
      description = ''
        Extra Python packages and xontrib packages to make available inside
        xonsh. When non-null, the xonsh derivation is overridden with these
        packages via its `extraPackages` argument.

        Leave as `null` (the default) to use the package unmodified.
      '';
    };

    shellAliases = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = literalExpression ''
        {
          g    = "git";
          ll   = "ls -l";
          ".." = "cd ..";
        }
      '';
      description = ''
        An attribute set of shell aliases. Each entry is emitted as
        `aliases["key"] = "value"` in the xonsh run control file.
      '';
    };

    sessionVariables = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = literalExpression ''
        {
          EDITOR = "nvim";
          PAGER  = "less";
        }
      '';
      description = ''
        Environment variables to set via xonsh's `$VAR = "value"` syntax.
        These are set unconditionally at every shell startup.
      '';
    };

    xontribs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = literalExpression ''[ "vox" "mpl" "coreutils" ]'';
      description = ''
        List of xontrib names to load via `xontrib load` at startup. The
        corresponding Python packages must be available, either through
        {option}`programs.xonsh.extraPackages` or {option}`home.packages`.
      '';
    };

    plugins = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = ''
                A unique name for this plugin, used as the file stem in
                {file}`~/.config/xonsh/rc.d/` (e.g. `"my-init"` →
                {file}`rc.d/my-init.xsh`).
              '';
            };
            src = mkOption {
              type = types.path;
              description = ''
                Path to a `.xsh` or `.py` file to install into
                {file}`~/.config/xonsh/rc.d/`. Xonsh executes all files
                in this directory at startup in alphabetical order.
              '';
            };
          };
        }
      );
      default = [ ];
      example = literalExpression ''
        [
          {
            name = "my-init";
            src  = ./my-xonsh-init.xsh;
          }
        ]
      '';
      description = ''
        A list of xonsh script files (`.xsh` or `.py`) to install into
        {file}`~/.config/xonsh/rc.d/`. Files are executed in alphabetical
        order at startup.
      '';
    };

    shellInit = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Xonsh code executed at shell startup in both interactive and
        non-interactive sessions. Runs before the login and interactive
        blocks.
      '';
    };

    loginShellInit = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Xonsh code executed only in login shells (`$XONSH_LOGIN` is `True`).
      '';
    };

    interactiveShellInit = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Xonsh code executed only in interactive shells
        (`$XONSH_INTERACTIVE` is `True`).
      '';
    };

    shellInitLast = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Xonsh code executed at the very end of the run control file, after
        all other init blocks. Useful for settings or overrides that must
        come last.
      '';
    };

    xonshrcExtra = mkOption {
      type = types.lines;
      default = "";
      example = literalExpression ''
        $XONSH_HISTORY_MATCH_ANYWHERE = True
        $XONSH_AUTOPAIR = True
      '';
      description = ''
        Extra xonsh code appended verbatim to the end of
        {file}`~/.config/xonsh/rc.xsh`. This is the escape hatch for
        settings not covered by the other options.
      '';
    };

    bashCompletion = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to configure xonsh to use bash completions by pointing
          `$BASH_COMPLETIONS` at the bash-completion package. This enables
          completion for programs that ship bash completion scripts.
        '';
      };

      package = lib.mkPackageOption pkgs "bash-completion" { };
    };
  };

  config = mkIf cfg.enable (
    lib.mkMerge [
      {
        home.packages = [ package ];

        xdg.configFile."xonsh/rc.xsh".text = rcText;
      }

      (mkIf (cfg.plugins != [ ]) {
        xdg.configFile = lib.listToAttrs (
          map (plugin: {
            name = "xonsh/rc.d/${plugin.name}.xsh";
            value = {
              source = plugin.src;
            };
          }) cfg.plugins
        );
      })

      (mkIf cfg.bashCompletion.enable {
        home.packages = [ cfg.bashCompletion.package ];

        programs.xonsh.interactiveShellInit = lib.mkAfter ''
          $BASH_COMPLETIONS = '${cfg.bashCompletion.package}/share/bash-completion/bash_completion'
        '';
      })
    ]
  );
}
