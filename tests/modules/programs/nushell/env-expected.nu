$env.FOO = 'BAR'


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
