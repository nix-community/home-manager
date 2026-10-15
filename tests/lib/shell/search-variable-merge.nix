{
  config,
  realPkgs,
  ...
}:

let
  inherit (config.lib) shell;
in
{
  # Put the helper in the test home so nmt.script can source it through $TESTED
  # instead of embedding a store path.
  home.file.".config/hm-search-merge-test.sh".text = ''
    ${shell.mergeSearchVariables {
      prepend = {
        SUBSTRING = [ "/usr/share" ];
        DEDUP = [
          "bar"
          "baz"
          "bar"
          ""
          "$EMPTY_ENTRY"
          "foo"
        ];
        EXPANDED = [ "$HOME/tools" ];
        COMMAND = [ "$(printf \"%s\" \"command with space\")" ];
        ARITHMETIC = [ "$((6 * 7))" ];
        BACKTICK = [ "`printf backtick`" ];
        LITERAL = [ "\\$NOT_EXPANDED/entry" ];
        ESCAPED_QUOTE_GLOB = [ "\\\"*" ];
        GLOB = [ "[a-z]" ];
        SEPARATOR = [ "a:b" ];
        COMPLETE = [ "qux" ];
        BOTH = [ "front" ];
      };
      append = {
        BOTH = [ "fallback" ];
        TRAILING = [ "/first" ];
      };
    }}
  '';

  nmt.script = ''
    script="$TESTED/home-files/.config/hm-search-merge-test.sh"
    assertFileExists home-files/.config/hm-search-merge-test.sh

    # NMT supplies Bash. dash and zsh must come from realPkgs because the
    # ordinary test package set is scrubbed to non-runnable paths.
    for shellBin in \
      "$BASH" \
      ${realPkgs.dash}/bin/dash \
      ${realPkgs.zsh}/bin/zsh; do

      # On the first merge, configured precedence repositions inherited duplicates.
      env -u __HM_SESS_VARS_MERGED \
        HOME=/runtime/home \
        EMPTY_ENTRY="" \
        SUBSTRING="/usr/share/ubuntu:/usr/share" \
        DEDUP="baz" \
        BOTH="fallback:middle:front" \
        COMPLETE="qux" \
        TRAILING="/first:/last" \
        "$shellBin" -uc '
          unset EXPANDED LITERAL GLOB SEPARATOR NOT_EXPANDED
          . "$1"

          [ "$SUBSTRING" = "/usr/share:/usr/share/ubuntu" ] \
            || { echo "SUBSTRING: $SUBSTRING"; exit 1; }
          [ "$DEDUP" = "bar:baz:foo" ] \
            || { echo "DEDUP: $DEDUP"; exit 1; }
          [ "$EXPANDED" = "/runtime/home/tools" ] \
            || { echo "EXPANDED: $EXPANDED"; exit 1; }
          [ "$COMMAND" = "command with space" ] \
            || { echo "COMMAND: $COMMAND"; exit 1; }
          [ "$ARITHMETIC" = "42" ] \
            || { echo "ARITHMETIC: $ARITHMETIC"; exit 1; }
          [ "$BACKTICK" = "backtick" ] \
            || { echo "BACKTICK: $BACKTICK"; exit 1; }
          [ "$LITERAL" = "\$NOT_EXPANDED/entry" ] \
            || { echo "LITERAL: $LITERAL"; exit 1; }
          [ "$ESCAPED_QUOTE_GLOB" = "\"*" ] \
            || { echo "ESCAPED_QUOTE_GLOB: $ESCAPED_QUOTE_GLOB"; exit 1; }
          [ "$GLOB" = "[a-z]" ] \
            || { echo "GLOB: $GLOB"; exit 1; }
          [ "$SEPARATOR" = "a:b" ] \
            || { echo "SEPARATOR: $SEPARATOR"; exit 1; }
          [ "$BOTH" = "front:middle:fallback" ] \
            || { echo "BOTH: $BOTH"; exit 1; }
          [ "$TRAILING" = "/last:/first" ] \
            || { echo "TRAILING: $TRAILING"; exit 1; }

          # Export the target even when every configured entry already exists.
          env | grep -qx "COMPLETE=qux" \
            || { echo "COMPLETE was not exported"; exit 1; }
          env | grep -qx "__HM_SESS_VARS_MERGED=1" \
            || { echo "merge marker was not exported"; exit 1; }

          for scratch in __hm_mode __hm_name __hm_sep __hm_cur __hm_add \
                         __hm_entry __hm_reposition __hm_work __hm_pre __hm_post; do
            eval "value=\''${$scratch-unset}"
            [ "$value" = unset ] || { echo "$scratch leaked: $value"; exit 1; }
          done
          command -v __hm_merge >/dev/null \
            && { echo "__hm_merge was not removed"; exit 1; }

          exit 0
        ' shell "$script" \
        || fail "$shellBin: first-merge search variable semantics broken"

      # Later merges preserve existing positions and remain idempotent.
      env __HM_SESS_VARS_MERGED=1 \
        HOME=/runtime/home \
        EMPTY_ENTRY="" \
        SUBSTRING="/usr/share/ubuntu:/usr/share" \
        DEDUP="baz" \
        BOTH="fallback:middle:front" \
        COMPLETE="qux" \
        TRAILING="/first:/last" \
        "$shellBin" -uc '
          unset EXPANDED LITERAL GLOB SEPARATOR NOT_EXPANDED
          . "$1"
          [ "$SUBSTRING" = "/usr/share/ubuntu:/usr/share" ] \
            || { echo "SUBSTRING moved on a later merge: $SUBSTRING"; exit 1; }
          [ "$DEDUP" = "bar:foo:baz" ] \
            || { echo "DEDUP: $DEDUP"; exit 1; }
          [ "$BOTH" = "fallback:middle:front" ] \
            || { echo "BOTH moved on a later merge: $BOTH"; exit 1; }
          [ "$TRAILING" = "/first:/last" ] \
            || { echo "TRAILING moved on a later merge: $TRAILING"; exit 1; }
          first="$SUBSTRING:$DEDUP:$BOTH:$TRAILING"
          . "$1"
          [ "$SUBSTRING:$DEDUP:$BOTH:$TRAILING" = "$first" ] \
            || { echo "not idempotent: $SUBSTRING:$DEDUP:$BOTH:$TRAILING"; exit 1; }
          exit 0
        ' shell "$script" \
        || fail "$shellBin: later-merge search variable semantics broken"
    done
  '';
}
