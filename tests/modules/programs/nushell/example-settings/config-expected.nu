load-env {
    "ENV_CONVERSIONS": {
        "PATH": {
            "from_string": ({|s| $s | split row (char esep) })
            "to_string": ({|v| $v | str join (char esep) })
        }
    }
    "FOO": "BAR"
    "LIST_VALUE": [
        "foo"
        "bar"
    ]
    "PROMPT_COMMAND": ({|| "> "})
}

$env.config.display_errors.exit_code = false
$env.config.hooks.pre_execution = [
    ({|| "pre_execution hook"})
]
$env.config.show_banner = false

let config = {
  filesize_metric: false
  table_mode: rounded
  use_ls_colors: true
}


alias "ll" = ls -a
alias "multi word alias" = cd -
alias "z" = __zoxide_z
