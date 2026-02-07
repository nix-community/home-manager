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
def "mixed" [] { echo 'start'; ls | where type == dir }
alias "multi word alias" = cd -
def "multi-cmd" [] { echo 'first'; echo 'second' }
def "pipe-cmd" [] { ls | where type == dir | length }
alias "z" = __zoxide_z
