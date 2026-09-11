{ lib }:

let

  sessionSearchShell = import ./session-search-shell.nix { inherit lib; };

  mkShellIntegrationOption =
    name:
    {
      config,
      baseName ? name,
      extraDescription ? "",
    }:
    let
      attrName = "enable${baseName}Integration";
    in
    lib.mkOption {
      default = config.home.shell.${attrName};
      defaultText = lib.literalMD "[](#opt-home.shell.${attrName})";
      example = false;
      description = "Whether to enable ${name} integration.${
        lib.optionalString (extraDescription != "") ("\n\n" + extraDescription)
      }";
      type = lib.types.bool;
    };

  # Produces a Bourne shell like variable export statement.
  export =
    n: v:
    let
      value = if builtins.isBool v then lib.boolToString v else toString v;
    in
    ''export ${n}="${value}"'';

  # Wrap a list of strings to a given line width.
  # Packs as many items as possible per line without exceeding maxWidth.
  # Returns a list of strings, each representing a line.
  #
  # Example: wrapLines ["item1" "item2" "very-long-item" "item3"] 20
  #   => ["item1 item2" "very-long-item" "item3"]
  wrapLines =
    items: maxWidth:
    let
      step =
        acc: item:
        let
          potentialLine = if acc.currentLine == "" then item else "${acc.currentLine} ${item}";
        in
        if lib.stringLength potentialLine <= maxWidth then
          acc // { currentLine = potentialLine; }
        else
          acc
          // {
            finishedLines = acc.finishedLines ++ [ acc.currentLine ];
            currentLine = item;
          };
      foldResult = lib.foldl' step {
        finishedLines = [ ];
        currentLine = "";
      } items;
    in
    foldResult.finishedLines ++ lib.optional (foldResult.currentLine != "") foldResult.currentLine;
  # POSIX sh does not define local variables, so remove every scratch name after
  # all calls.
  mergeScratchVariables = [
    "__hm_mode"
    "__hm_name"
    "__hm_sep"
    "__hm_cur"
    "__hm_add"
    "__hm_entry"
    "__hm_reposition"
    "__hm_work"
    "__hm_pre"
    "__hm_post"
  ];

  # Double-quote entry values so expansions run when the block is sourced.
  mkMergeCall =
    mode: sep: name: values:
    lib.concatStringsSep " " (
      [
        "__hm_merge"
        mode
        name
        ''"${sessionSearchShell.escapeDoubleQuoted sep}"''
      ]
      ++ map (value: ''"${sessionSearchShell.escapeDoubleQuoted value}"'') values
    );

  mergeSearchVariables =
    {
      prepend ? { },
      append ? { },
    }:
    let
      mkCalls =
        mode: variables:
        lib.concatStringsSep "\n" (
          map (name: mkMergeCall mode ":" name variables.${name}) (lib.attrNames variables)
        );
      calls = lib.concatStringsSep "\n" (
        lib.filter (value: value != "") [
          (mkCalls "prepend" prepend)
          (mkCalls "append" append)
        ]
      );
    in
    if prepend == { } && append == { } then
      ""
    else
      ''
        ${builtins.readFile ./session-search-merge.sh}
        ${calls}
        export __HM_SESS_VARS_MERGED=1
        unset -f __hm_merge
        unset ${lib.concatStringsSep " " mergeScratchVariables}
      '';

  isSelfReferential =
    name: value:
    lib.isString value
    && (
      let
        dollar = "$";
        expansionStart = "${dollar}{";
        escapedName = lib.escapeRegex name;
        refers =
          text:
          let
            # Escaped characters and `$$` cannot begin a variable reference.
            plainParts = lib.filter lib.isString (builtins.split ''(\\.|[$][$])'' text);
            refersInPart =
              part:
              builtins.match ".*[$][{]?${escapedName}([^A-Za-z0-9_].*)?" part != null
              || builtins.match ".*[$][{]#${escapedName}[}].*" part != null;
          in
          lib.any refersInPart plainParts;
        isWholeExpansion =
          text:
          let
            length = lib.stringLength text;
            # Keep nested parameter expansions inside the outer expression.
            scan =
              index: depth:
              if index >= length then
                false
              else if builtins.substring index 2 text == expansionStart then
                scan (index + 2) (depth + 1)
              else if builtins.substring index 1 text == "}" then
                if depth == 1 then index == length - 1 else scan (index + 1) (depth - 1)
              else if builtins.substring index 1 text == "\\" then
                scan (index + 2) depth
              else
                scan (index + 1) depth;
          in
          lib.hasPrefix expansionStart text && scan 2 1;
        nameExpansionStart = "${expansionStart}${name}";
        expansionBodyFor =
          text:
          if isWholeExpansion text && lib.hasPrefix nameExpansionStart text then
            builtins.substring (lib.stringLength nameExpansionStart) (
              lib.stringLength text - lib.stringLength nameExpansionStart - 1
            ) text
          else
            null;
        operatorFor =
          body:
          if body == null then
            null
          else
            lib.findFirst (candidate: lib.hasPrefix candidate body) null [
              ":-"
              ":="
              ":?"
              ":+"
              "-"
              "="
              "?"
              "+"
            ];
        isStableValue =
          text:
          let
            body = expansionBodyFor text;
            operator = operatorFor body;
            word = if operator == null then null else lib.removePrefix operator body;
          in
          !refers text
          || text == "${dollar}${name}"
          || body == ""
          || lib.elem operator [
            ":-"
            ":="
            ":?"
            "-"
            "="
            "?"
          ]
          || (
            lib.elem operator [
              ":+"
              "+"
            ]
            && isStableValue word
          );
      in
      refers value && !isStableValue value
    );

  /*
    Build the warning list for self-referential entries of a session-variable
    option. Shared so every shell that has its own `sessionVariables` reports
    the same thing.

    # Type

    ```
    selfReferenceWarnings :: { option, optionPath, rationale, renderValue ? id } -> [ String ]
    ```
  */
  selfReferenceWarnings =
    {
      option,
      optionPath,
      rationale,
      renderValue ? lib.id,
    }:
    let
      offenders = lib.attrNames (
        lib.filterAttrs (name: value: isSelfReferential name (renderValue value)) option.value
      );
      formatOffender =
        name:
        let
          files = lib.hm.options.attrDefinitionFiles option name;
        in
        "${name}, defined in ${lib.options.showFiles files}";
    in
    lib.optional (offenders != [ ]) ''
      The following ${optionPath} may change when applied again:

        ${lib.concatMapStringsSep "\n  " formatOffender offenders}

      ${lib.removeSuffix "\n" rationale}

      For search paths, use home.sessionPath,
      home.sessionSearchVariables, or home.sessionSearchVariablesAppend.
      Those options add only the entries that are missing. For other
      variables, assign a complete value without referring to its previous
      contents.

      This check is best-effort and detects only direct parameter references
      such as $NAME, ''${NAME...}, and ''${#NAME}.
    '';

in
{
  inherit
    export
    wrapLines
    selfReferenceWarnings
    ;

  /**
    Generate a complete POSIX shell block that merges entries into
    colon-delimited search variables.

    Prepends run before appends. The generated block exports a process marker
    so later blocks preserve inherited entry positions.

    Entries are evaluated in a double-quoted shell context. Parameter and
    arithmetic expansions and both command-substitution forms stay active.
    Write `\"` for a literal `"`. Plain glob and tilde characters remain
    literal while the surrounding double-quoted context is intact.

    Returns an empty string when both attribute sets are empty.

    # Inputs

    `prepend`

    : Attribute set that maps variable names to entries added at the front

    `append`

    : Attribute set that maps variable names to entries added at the end

    # Type

    ```
    mergeSearchVariables :: { prepend ? AttrSet [ String ], append ? AttrSet [ String ] } -> String
    ```
  */
  inherit mergeSearchVariables;

  # Given an attribute set containing shell variable names and their
  # assignment, this function produces a string containing an export
  # statement for each set entry.
  exportAll =
    vars:
    lib.concatStringsSep "\n" (lib.mapAttrsToList export (lib.filterAttrs (_k: v: v != null) vars));

  # Formats a list of items for shell array content with intelligent width optimization.
  # IMPORTANT: This formats the CONTENTS of an array (what goes inside parentheses),
  # not a complete array definition. Use lib.hm.zsh.define for complete definitions.
  #
  # Uses lib.escapeShellArg for robust shell escaping (handles spaces, quotes, special chars).
  # Packs multiple items per line to optimize terminal width (~78 chars per line).
  # Short arrays (≤3 items, ≤80 chars total) use single-line format.
  #
  # Example outputs:
  #   Empty:       ""
  #   Simple:      item1 item2 item3
  #   With spaces: 'item one' 'item two' 'item three'
  #   Long arrays: \n  item1 item2 item3\n  item4 item5\n
  #
  # Built from composable helpers: wrapLines, formatMultiLine
  formatShellArrayContent =
    items:
    let
      quotedItems = lib.map lib.escapeShellArg items;
      formatMultiLine = lines: "\n  ${lib.concatStringsSep "\n  " lines}\n";
      wrapped = wrapLines quotedItems 78;
    in
    formatMultiLine wrapped;

  mkBashIntegrationOption = mkShellIntegrationOption "Bash";
  mkFishIntegrationOption = mkShellIntegrationOption "Fish";
  mkIonIntegrationOption = mkShellIntegrationOption "Ion";
  mkNushellIntegrationOption = mkShellIntegrationOption "Nushell";
  mkZshIntegrationOption = mkShellIntegrationOption "Zsh";
}
