{ lib }:

let

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
  # Prepare a value for interpolation inside a double-quoted shell word.
  # `$` stays expandable and existing backslash escapes keep the meaning
  # double quotes give them, so `\$HOME` remains a literal `$HOME` while a
  # lone backslash before any other character stays a literal backslash.
  escapeDoubleQuoted =
    let
      escapeLiteral = lib.replaceStrings [ "\\" "\"" "`" ] [ "\\\\" "\\\"" "\\`" ];
      handlePart =
        part:
        if lib.isString part then
          escapeLiteral part
        else
          let
            c = lib.head part;
          in
          # These four sequences already escape within double quotes. A
          # backslash before anything else — including a newline, whose
          # line-continuation semantics we deliberately do not preserve —
          # is literal and must itself be escaped.
          if c == "$" || c == "\\" || c == "\"" || c == "`" then "\\${c}" else escapeLiteral "\\${c}";
    in
    value: lib.concatMapStrings handlePart (builtins.split ''\\(.)'' value);

  # Add missing non-empty entries without moving existing ones. Keep this
  # inline and POSIX-compatible because Babelfish mistranslates quoted
  # positional parameters in case patterns.
  idempotentMerge =
    combine: sep: n: v:
    let
      values = lib.unique (lib.filter (value: value != "") v);
      # Keep values separate; splitting a joined string would corrupt entries
      # that contain the separator.
      addValue = value: ''
        __hm_entry="${escapeDoubleQuoted value}"
        if [ -n "$__hm_entry" ]; then
          case "${sep}$__hm_cur${sep}$__hm_add${sep}" in
            *"${sep}$__hm_entry${sep}"*) ;;
            *) __hm_add="$__hm_add''${__hm_add:+${sep}}$__hm_entry" ;;
          esac
        fi'';
      addValues = lib.concatMapStringsSep "\n" addValue values;
      indentedAddValues = lib.optionalString (values != [ ]) (
        lib.replaceStrings [ "\n" ] [ "\n  " ] addValues
      );
      # Command substitution strips trailing newlines, so keep a sentinel until
      # the value returns to the parent shell.
    in
    ''
      ${n}=$(
        __hm_cur="''${${n}-}"
        __hm_add=""
        __hm_entry=""
        ${indentedAddValues}
        if [ -n "$__hm_add" ]; then
          __hm_cur="${combine sep}"
        fi
        printf '%s.' "$__hm_cur"
      )
      ${n}="''${${n}%?}"
      export ${n}
    '';
in
{
  inherit export wrapLines;

  # Produces a Bourne shell like statement that prepend new values to
  # an possibly existing variable, using sep(arator).
  # Example:
  #   prependToVar ":" "PATH" [ "$HOME/bin" "$HOME/.local/bin" ]
  #   => "$HOME/bin:$HOME/.local/bin:${PATH:+:}\$PATH"
  prependToVar =
    sep: n: v:
    "${lib.concatStringsSep sep v}\${${n}:+${sep}}\$${n}";

  /**
    Generate POSIX shell code that prepends missing entries to a variable.

    # Type

    ```
    idempotentPrepend :: String -> String -> [ String ] -> String
    ```
  */
  idempotentPrepend = idempotentMerge (sep: "$__hm_add\${__hm_cur:+${sep}}$__hm_cur");

  /**
    Generate POSIX shell code that appends missing entries to a variable.

    # Type

    ```
    idempotentAppend :: String -> String -> [ String ] -> String
    ```
  */
  idempotentAppend = idempotentMerge (sep: "$__hm_cur\${__hm_cur:+${sep}}$__hm_add");

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
