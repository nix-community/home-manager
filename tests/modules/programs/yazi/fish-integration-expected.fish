function yy
    set -l tmp (mktemp -t "yazi-cwd.XXXXX")
    command yazi $argv --cwd-file="$tmp"
    if read cwd <"$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end
