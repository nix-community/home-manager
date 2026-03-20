{
  news-validation =
    {
      config,
      pkgs,
      ...
    }:
    {
      home.file."news-test.json".source = config.news.json.output;

      nmt.script = # Bash
        ''
          ALL_ERRORS=""
          JQ_CMD="${pkgs.jq}/bin/jq"
          news_json="$TESTED/home-files/news-test.json"

          echo "Testing news validation..."
          echo "Looking for news file at: $news_json"

          if [[ ! -f "$news_json" ]]; then
            fail "news-test.json file not found at $news_json"
          fi

          if ! "$JQ_CMD" . "$news_json" > /dev/null 2>&1; then
            fail "news.json is not valid JSON"
          fi

          run_check() {
            local description="$1"
            local jq_filter="$2"
            local fail_message="$3"

            echo "--> Checking: $description"
            local output
            local exit_code=0

            output=$("$JQ_CMD" -re "$jq_filter" "$news_json" 2>&1) || exit_code=$?

            if [[ $exit_code -eq 3 ]]; then
              echo "!!! JQ COMPILE ERROR in check: '$description'"
              printf "Error details:\n%s\n" "$output"
              fail "FATAL: Fix the jq filter for the check."
            fi

            if [[ -n "$output" ]]; then
              local error_block
              printf -v error_block '\n%s\nFAIL: %s\n%s\n%s' \
                "=======================================================================" \
                "$fail_message" \
                "-----------------------------------------------------------------------" \
                "$output"

              ALL_ERRORS+="$error_block"
            fi
          }

          echo "Validating JSON content..."

          run_check \
            "Entries array is not empty" \
            'select((.entries | length) <= 0) | "Found only \(.entries | length) entries"' \
            "news.entries should not be empty"

          run_check \
            "Required fields are present (time, message, condition, id)" \
            '.entries[] | select(has("time", "message", "condition", "id") | not) | "ID: \(.id // "unknown") | Message: Missing one or more required fields."' \
            "All news entries must have time, message,condition, and id fields"

          run_check \
           "Timestamps are valid, 4-digit year, ISO-8601 UTC dates" \
           '
             .entries[] | select(
               # Condition 1: Check if the format is correct (4-digit year, etc.)
               (.time | test("^20[0-9]{2}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\\+00:00$") | not)
               or
               # Condition 2: Check if the date is logically valid (no Feb 30)
               ((try (.time | sub("\\+00:00$"; "Z") | fromdateiso8601) catch null) == null)
             ) | "Time: \(.time) | ID: \(.id // "unknown") | Message: Invalid format or non-existent date"' \
           "All timestamps must be valid, well-formed ISO-8601 dates in UTC with a 4-digit year"

          run_check \
            "Message fields are non-empty strings" \
            '.entries[] | select(.message == "" or (.message | type) != "string") | "ID: \(.id // "unknown") | Message: Message field is empty or not a string"' \
            "All message fields must be non-empty strings"

          run_check \
            "ID fields are non-empty strings" \
            '.entries[] | select(.id == "" or (.id | type) != "string") | "ID: \(.id // "undefined") | Message: ID field is empty or not a string"' \
            "All id fields must be non-empty strings"

          run_check \
            "Condition fields are boolean" \
            '.entries[] | select((.condition | type) != "boolean") | "ID: \(.id) | Message: Condition field is not a boolean (\(.condition | tostring))"' \
            "All condition fields must be booleans"

          run_check \
            "IDs are unique" \
            '.entries | group_by(.id)[] | select(length > 1) | "Duplicate ID: \(. [0].id) | Found at times: \([.[] | .time] | join(", "))"' \
            "All news entry IDs must be unique"

          if [[ -n "$ALL_ERRORS" ]]; then
            echo ""
            echo "##########################################"
            echo "!!! VALIDATION FAILED - All issues found:"
            echo "##########################################"
            printf "%s\n" "$ALL_ERRORS"
            echo "======================================================================="
            fail "Please fix the validation issues listed above."
          else
            echo ""
            echo "All news validation tests passed successfully!"
          fi
        '';
    };
}
