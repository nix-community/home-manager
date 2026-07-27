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
  # Escapes a value for interpolation into a double-quoted shell string.
  # `$` is deliberately left alone: values are documented to have parameters
  # such as `$HOME` expanded by the shell.
  escapeDoubleQuoted = lib.replaceStrings [ "\\" "\"" "`" ] [ "\\\\" "\\\"" "\\`" ];

  # Produces Bourne shell statements that merge new values into a
  # possibly existing variable in an idempotent way: only non-empty
  # values not already present in the variable or earlier in the input
  # are added. Sourcing the output multiple times introduces no new
  # duplicates and never reorders entries that other tools (dev shells,
  # direnv, system startup files) deliberately placed there.
  #
  # `combine` receives the separator and returns the shell expression
  # joining the collected additions with the existing value, which is
  # what distinguishes prepending from appending.
  #
  # The generated code must stay within the POSIX subset that
  # babelfish can translate, since the fish module translates
  # hm-session-vars.sh with it. In particular this must not be factored
  # into a shell function taking the value as a positional parameter:
  # babelfish drops the quoting around `$1`/`$2` and mistranslates them
  # inside `case` patterns, which silently stops anything being added.
  idempotentMerge =
    combine: sep: n: v:
    let
      # One block per value, rather than joining the values and splitting
      # them again at runtime. Splitting would corrupt any value that
      # legitimately contains the separator, such as a `NIX_PATH` entry
      # holding a URL. The value is only ever read back through a quoted
      # expansion, so neither it nor the separator needs to be free of glob
      # metacharacters.
      addValue = value: ''
        __hm_entry="${escapeDoubleQuoted value}"
        if [ -n "$__hm_entry" ]; then
          case "${sep}$__hm_cur${sep}$__hm_add${sep}" in
            *"${sep}$__hm_entry${sep}"*) ;;
            *) __hm_add="$__hm_add''${__hm_add:+${sep}}$__hm_entry" ;;
          esac
        fi'';
    in
    ''
      __hm_cur="''${${n}-}"
      __hm_add=""
      ${lib.concatMapStringsSep "\n" addValue v}
      # Always export, even when nothing was added: the variable may be
      # set but not exported in the sourcing shell.
      if [ -n "$__hm_add" ]; then
        __hm_cur="${combine sep}"
      fi
      export ${n}="$__hm_cur"
      unset __hm_cur __hm_add __hm_entry
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

  # Prepend new values, keeping any already-present entry at its current
  # position. Use for search paths where Home Manager's directories should win
  # over inherited ones, e.g. PATH.
  idempotentPrepend = idempotentMerge (sep: "$__hm_add\${__hm_cur:+${sep}}$__hm_cur");

  # Append new values, keeping any already-present entry at its current
  # position. Use for trailing fallbacks that must stay behind inherited
  # entries, e.g. a system-wide terminfo directory.
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
