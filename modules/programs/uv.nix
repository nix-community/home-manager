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

          When enabled, managed Python versions that no longer match any entry in
          {option}`programs.uv.python.versions` are uninstalled before the listed
          versions are installed, so the set is fully declarative. uv resolves
          each requested version to the install target it would produce, so only
          the difference is removed; versions that are already correct are left
          untouched rather than reinstalled.

          ::: {.warning}
          Versions installed manually with {command}`uv python install` are also
          removed, since they are not listed here.
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

          When enabled, installed tools whose package name is no longer listed in
          {option}`programs.uv.tool.packages` are uninstalled before the listed
          tools are installed, so the set is fully declarative. Only the
          difference is removed; tools that are already installed are left for the
          upgrade step rather than reinstalled.

          ::: {.warning}
          Tools installed manually with {command}`uv tool install` are also
          removed, since they are not listed here.
          :::
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable (
    let
      uvBin = if cfg.package != null then lib.getExe cfg.package else "uv";

      # PEP 503 normalization: collapse every run of `-`, `_`, `.` to a single
      # `-`, then lowercase. `builtins.split` returns string segments
      # interleaved with match sublists, so replacing each match with `-` and
      # keeping the segments verbatim reproduces `re.sub("[-_.]+", "-", name)`.
      canonicalName =
        name:
        lib.toLower (
          lib.concatMapStrings (x: if builtins.isList x then "-" else x) (builtins.split "[-_.]+" name)
        );

      # Requested tool names to keep, computed at build time: take the leading
      # PEP 508 name (dropping extras and version specifiers) and PEP 503
      # normalize it. uv keys its tool directory by this same normalized name.
      toolName =
        spec:
        let
          m = builtins.match "([A-Za-z0-9._-]+).*" spec;
        in
        canonicalName (if m == null then spec else builtins.head m);
      toolKeep = lib.unique (map toolName toolCfg.packages);
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
              # Prune declaratively, but only touch what actually changed. uv has
              # no declarative install, so instead of uninstalling and
              # reinstalling everything we ask uv for the target each request
              # would install (delegating all matching to uv, `--managed-python`
              # keeps system Pythons out of reach) and uninstall every managed
              # install that is not one of those targets. uv retains superseded
              # patch releases on upgrade, so we resolve to the install target
              # (`.[0]`, the newest match) rather than every installed match;
              # otherwise stale patches would match a request and never be
              # pruned. jq does the set difference over uv's public JSON output,
              # so there is no text munging here, and an empty request list
              # resolves the keep set to `[]`, pruning everything. Kept targets
              # are left for the install/upgrade path below.
              uvKeep=$(
                for uvReq in ${escapeShellArgs pyCfg.versions}; do
                  ${uvBin} python list "$uvReq" --managed-python --output-format json
                done | jq -s 'map(.[0].key // empty)'
              )
              ${uvBin} python list --only-installed --managed-python --output-format json \
                | jq -r --argjson keep "$uvKeep" '([.[].key] | unique) - $keep | .[]' \
                | while read -r uvKey; do
                    run ${uvBin} python uninstall $VERBOSE_ARG "$uvKey"
                  done
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
            # Prune declaratively, but only uninstall tools that are no longer
            # requested. uv keeps each installed tool in its own directory under
            # `uv tool dir`, named by the PEP 503-normalized package name, so the
            # directory listing is the installed set with no output parsing. We
            # diff it against the requested names (normalized at build time, see
            # toolKeep) and uninstall the rest. Kept tools are left for the
            # install/upgrade path below.
            uvToolDir=$(${uvBin} tool dir)
            if [ -d "$uvToolDir" ]; then
              ls -1 "$uvToolDir" | sort -u \
                | comm -23 - <(printf '%s\n' ${escapeShellArgs toolKeep} | sort -u) \
                | while read -r uvTool; do
                    run ${uvBin} tool uninstall $VERBOSE_ARG "$uvTool"
                  done
            fi
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
