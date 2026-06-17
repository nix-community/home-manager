{
  pkgs,
  config,
  lib,
  ...
}:

let

  inherit (lib)
    mkEnableOption
    mkPackageOption
    mkOption
    literalExpression
    types
    optionalString
    escapeShellArg
    escapeShellArgs
    concatMapStringsSep
    ;

  tomlFormat = pkgs.formats.toml { };
  cfg = config.programs.uv;

  pyCfg = cfg.python;
  toolCfg = cfg.tool;

in
{
  meta.maintainers = with lib.maintainers; [
    mirkolenz
    bittner
  ];

  options.programs.uv = {
    enable = mkEnableOption "uv";

    package = mkPackageOption pkgs "uv" { nullable = true; };

    settings = mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = literalExpression ''
        {
          python-downloads = "never";
          python-preference = "only-system";
          pip.index-url = "https://test.pypi.org/simple";
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/uv/uv.toml`.
        See <https://docs.astral.sh/uv/configuration/files/>
        and <https://docs.astral.sh/uv/reference/settings/>
        for more information.
      '';
    };

    python = {
      versions = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [
          "3.13"
          "3.12"
          "pypy@3.11"
        ];
        description = ''
          Python versions to install with `uv python` during activation. Each
          entry is passed verbatim to {command}`uv python install`, so any
          request it accepts works (e.g. `"3.13"`, `"3.12.4"`, `"pypy@3.11"`,
          `"cpython-3.14.5+freethreaded"`).

          Entries without a patch component (e.g. `"3.13"`, `"pypy@3.11"`) are
          installed with {command}`--upgrade`, so on every activation they track
          the latest patch release. Entries pinned to an exact patch (e.g.
          `"3.12.4"`) are installed as requested and never upgraded, since uv
          rejects upgrading them. See
          <https://docs.astral.sh/uv/concepts/python-versions/> for more
          information.
        '';
      };

      default = mkOption {
        type = types.coercedTo types.str lib.singleton (types.listOf types.str);
        default = [ ];
        example = [
          "3.13"
          "pypy@3.11"
        ];
        description = ''
          Versions from {option}`programs.uv.python.versions` to set as default
          Python versions, each installed with
          {command}`uv python install --default`.

          {command}`--default` provides the unversioned executable for the
          request's implementation, so defaults of different implementations do
          not conflict: a CPython request provides {command}`python` and
          {command}`python3`, a PyPy request provides {command}`pypy` and
          {command}`pypy3`, a GraalPy request provides {command}`graalpy` and
          {command}`graalpy3`. List one request per implementation to set them
          all. A bare string is accepted as a single-element list.
        '';
      };

      prune = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to make the set of managed Python versions fully declarative.

          When enabled, {command}`uv python uninstall --all` is run before
          installing {option}`programs.uv.python.versions`, so versions that are
          no longer listed are removed.

          ::: {.warning}
          uv has no declarative install command, so this uninstalls and
          reinstalls all listed versions on every activation, which is slow.
          Versions installed manually with {command}`uv python install` are also
          removed.
          :::
        '';
      };
    };

    tool = {
      packages = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [
          "ruff"
          "black==24.1.0"
          "poetry[plugin]"
        ];
        description = ''
          Tools to install with `uv tool` during activation. Each entry is passed
          verbatim to {command}`uv tool install`, so version specifiers and extras
          work (e.g. `"black==24.1.0"`, `"poetry[plugin]"`).

          On every activation {command}`uv tool upgrade` is run for the listed
          tools, which upgrades them to the latest version allowed by the
          constraints they were installed with (e.g. `"black==24.1.0"` stays
          pinned). Tools that are not listed are left untouched. See
          <https://docs.astral.sh/uv/concepts/tools/> for more information.
        '';
      };

      prune = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to make the set of installed tools fully declarative.

          When enabled, {command}`uv tool uninstall --all` is run before
          installing {option}`programs.uv.tool.packages`, so tools that are no
          longer listed are removed.

          ::: {.warning}
          uv has no declarative install command, so this uninstalls and
          reinstalls all listed tools on every activation, which is slow. Tools
          installed manually with {command}`uv tool install` are also removed.
          :::
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable (
    let
      uvBin = if cfg.package != null then lib.getExe cfg.package else "uv";
    in
    {
      home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

      xdg.configFile."uv/uv.toml" = lib.mkIf (cfg.settings != { }) {
        source = tomlFormat.generate "uv-config" cfg.settings;
      };

      assertions =
        let
          duplicates = xs: lib.unique (builtins.filter (x: lib.count (y: y == x) xs > 1) xs);
          noDuplicates = name: xs: {
            assertion = duplicates xs == [ ];
            message = ''
              programs.uv.${name} contains duplicate entries: ${
                concatMapStringsSep ", " (x: ''"${x}"'') (duplicates xs)
              }.
            '';
          };
        in
        [
          (noDuplicates "python.versions" pyCfg.versions)
          (noDuplicates "python.default" pyCfg.default)
          (noDuplicates "tool.packages" toolCfg.packages)
          {
            assertion = lib.all (d: builtins.elem d pyCfg.versions) pyCfg.default;
            message = ''
              Every programs.uv.python.default entry must also be listed, spelled
              identically, in programs.uv.python.versions.
            '';
          }
          {
            assertion =
              cfg.package != null
              || (pyCfg.versions == [ ] && !pyCfg.prune && toolCfg.packages == [ ] && !toolCfg.prune);
            message = ''
              `programs.uv.package` cannot be null when `programs.uv.python` or
              `programs.uv.tool` manages installations during activation.
            '';
          }
        ];

      home.activation.uvPython = lib.mkIf (pyCfg.versions != [ ] || pyCfg.prune) (
        # Run after linkGeneration so uv sees the freshly linked uv.toml.
        lib.hm.dag.entryAfter [ "linkGeneration" ] (
          let
            # uv only upgrades major/minor requests; an exact patch (a
            # `MAJOR.MINOR.PATCH` triple, e.g. "3.12.4" or
            # "cpython-3.14.5+freethreaded") is rejected by `--upgrade`. So
            # unpinned entries are installed with `--upgrade` (tracking the
            # latest patch on every activation) and pinned entries with a plain
            # install (left as requested).
            hasPatch = v: builtins.match ".*[0-9]+[.][0-9]+[.][0-9]+.*" v != null;
            upgradeFlag = v: optionalString (!hasPatch v) "--upgrade ";

            # Defaults are installed (with --default) one per entry up front; the
            # rest follow, batched by whether they are upgraded. Every default is
            # guaranteed to be in versions by the assertion above, so each
            # version is installed exactly once.
            rest = builtins.filter (v: !builtins.elem v pyCfg.default) pyCfg.versions;
            restUpgrade = builtins.filter (v: !hasPatch v) rest;
            restPinned = builtins.filter hasPatch rest;
          in
          ''
            ${optionalString pyCfg.prune ''
              run ${uvBin} python uninstall $VERBOSE_ARG --all
            ''}
            ${concatMapStringsSep "\n" (
              d: "run ${uvBin} python install $VERBOSE_ARG --default ${upgradeFlag d}${escapeShellArg d}"
            ) pyCfg.default}
            ${optionalString (restUpgrade != [ ]) ''
              run ${uvBin} python install $VERBOSE_ARG --upgrade ${escapeShellArgs restUpgrade}
            ''}
            ${optionalString (restPinned != [ ]) ''
              run ${uvBin} python install $VERBOSE_ARG ${escapeShellArgs restPinned}
            ''}
          ''
        )
      );

      home.activation.uvTool = lib.mkIf (toolCfg.packages != [ ] || toolCfg.prune) (
        # Run after linkGeneration so uv sees the freshly linked uv.toml.
        lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          ${optionalString toolCfg.prune ''
            run ${uvBin} tool uninstall $VERBOSE_ARG --all
          ''}
          ${concatMapStringsSep "\n" (
            t: "run ${uvBin} tool install $VERBOSE_ARG ${escapeShellArg t}"
          ) toolCfg.packages}
          ${optionalString (toolCfg.packages != [ ]) ''
            run ${uvBin} tool upgrade $VERBOSE_ARG ${escapeShellArgs toolCfg.packages}
          ''}
        ''
      );
    }
  );
}
