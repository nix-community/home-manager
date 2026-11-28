# Native counterpart to session-search-merge.sh. Babelfish cannot translate
# the POSIX helper's quoted pattern removal. Fish also stores names ending in
# PATH as lists and colon-joins them on export, so inherited path values must be
# read in joined form.
#
#   __hm_merge <prepend|append> <NAME> <SEP> [ENTRY...]
#
# SEP must be `:` when NAME ends in PATH, matching Fish's path-variable rule.
#
# Match the joined string, not split elements, so an entry containing the
# separator remains one unit. `string replace` is literal, so glob and regex
# characters are compared as written.
#
# Keep this in step with session-search-merge.sh: any observable behavior
# change there must be mirrored here, and both must produce identical results
# for the same inputs.
function __hm_merge
    set -l __hm_mode $argv[1]
    set -l __hm_name $argv[2]
    set -l __hm_sep $argv[3]
    set -l __hm_entries $argv[4..-1]

    set -l __hm_seplen (string length -- $__hm_sep)
    set -l __hm_values
    if set -q $__hm_name
        set __hm_values $$__hm_name
    end

    # Fish command substitutions trim trailing newlines. Mark the end before a
    # transformation, then use split0 to recover the exact result.
    set -l __hm_sentinel __HM_SESS_VARS_END
    while string match -q -- "*$__hm_sentinel*" "$__hm_sep" $__hm_values $__hm_entries
        set __hm_sentinel _$__hm_sentinel
    end
    set -l __hm_sentinel_pattern "$__hm_sentinel\\z"

    # A trailing PATH in the name is Fish's rule for list-typed variables.
    set -l __hm_is_path 0
    if string match -q -- '*PATH' $__hm_name
        set __hm_is_path 1
    end

    set -l __hm_cur ""
    if set -q $__hm_name
        if test $__hm_is_path -eq 1
            if test (count $__hm_values) -eq 0
                set __hm_values $__hm_sentinel
            else
                set __hm_values[-1] "$__hm_values[-1]$__hm_sentinel"
            end
            set __hm_cur (
                string join -- $__hm_sep $__hm_values |
                    string replace -r -- $__hm_sentinel_pattern "\\x00" |
                    string split0
            )[1]
        else
            set __hm_cur $__hm_values
        end
    end

    # The first merge repositions entries; later merges preserve inherited
    # positions. See session-search-merge.sh for the ordering rationale.
    set -l __hm_reposition 0
    # Match the POSIX helper's empty-marker behavior.
    if test -z "$__HM_SESS_VARS_MERGED"
        set __hm_reposition 1
    end

    set -l __hm_add ""
    for __hm_entry in $__hm_entries
        # Most search-path consumers interpret an empty entry as current
        # directory.
        test -n "$__hm_entry"
        or continue

        set -l __hm_probe "$__hm_sep$__hm_add$__hm_sep"
        set -l __hm_deduped (
            string replace -- "$__hm_sep$__hm_entry$__hm_sep" "$__hm_sep" "$__hm_probe$__hm_sentinel" |
                string replace -r -- $__hm_sentinel_pattern "\\x00" |
                string split0
        )[1]
        if test "$__hm_deduped" != "$__hm_probe"
            continue
        end

        set -l __hm_work "$__hm_sep$__hm_cur$__hm_sep"
        set -l __hm_stripped $__hm_work
        while true
            set -l __hm_next (
                string replace -- "$__hm_sep$__hm_entry$__hm_sep" "$__hm_sep" "$__hm_stripped$__hm_sentinel" |
                    string replace -r -- $__hm_sentinel_pattern "\\x00" |
                    string split0
            )[1]
            test "$__hm_next" = "$__hm_stripped"
            and break
            set __hm_stripped $__hm_next
        end

        if test $__hm_reposition -eq 1
            # Every replacement preserves the wrapper separators.
            set __hm_stripped (
                string sub -s (math $__hm_seplen + 1) -- "$__hm_stripped$__hm_sentinel" |
                    string replace -r -- $__hm_sentinel_pattern "\\x00" |
                    string split0
            )[1]
            set -l __hm_sep_pattern (string escape --style=regex "$__hm_sep")
            set __hm_stripped (
                string replace -r -- "$__hm_sep_pattern$__hm_sentinel_pattern" $__hm_sentinel "$__hm_stripped$__hm_sentinel" |
                    string replace -r -- $__hm_sentinel_pattern "\\x00" |
                    string split0
            )[1]
            set __hm_cur $__hm_stripped
        else if test "$__hm_stripped" != "$__hm_work"
            # Already present, and a later merge must not move it.
            continue
        end

        if test -n "$__hm_add"
            set __hm_add "$__hm_add$__hm_sep$__hm_entry"
        else
            set __hm_add $__hm_entry
        end
    end

    if test -n "$__hm_add"
        if test -n "$__hm_cur"
            if test "$__hm_mode" = prepend
                set __hm_cur "$__hm_add$__hm_sep$__hm_cur"
            else
                set __hm_cur "$__hm_cur$__hm_sep$__hm_add"
            end
        else
            set __hm_cur $__hm_add
        end
    end

    set -gx $__hm_name $__hm_cur
end
