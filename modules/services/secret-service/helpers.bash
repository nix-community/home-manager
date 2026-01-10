set -o pipefail

# Check if the default collection exists and is unlocked
# If the first argument is set, it has to be the default collection, otherwise it will return 1
function checkUnlock {
    local default_collection
    default_collection="$(dbus-send --dest=org.freedesktop.secrets --print-reply=literal /org/freedesktop/secrets org.freedesktop.Secret.Service.ReadAlias 'string:default' | head -n1 | tr -d " " || true)"
    [[ "$default_collection" =~ ^/org/freedesktop/secrets/collection.*$ ]] || return 1

    local changed_collection="${1:-$default_collection}"
    [[ "$changed_collection" != "$default_collection" ]] && return 1

    local currently_locked
    currently_locked="$(dbus-send --dest=org.freedesktop.secrets --print-reply=literal "$default_collection" org.freedesktop.DBus.Properties.Get string:org.freedesktop.Secret.Collection string:Locked | grep -Po "(true|false)")"
    [[ "$currently_locked" != "false" ]] && return 1
    return 0
}

# Wait for the default collection to be unlocked
function waitForUnlock {
    # Instantly return if the collection is already unlocked
    checkUnlock && return 0

    echo "Waiting for the default collection to be unlocked..."
    local next_line_contains_name=false
    while read -r line; do
        if [[ $next_line_contains_name == true ]]; then
            COLLECTION="$(echo "$line" | grep -Po '(?<=")/org/freedesktop/secrets/collection/[^"/]+')"
            if checkUnlock "$COLLECTION"; then
                echo "Default collection was unlocked."
                return 0
            fi
            next_line_contains_name=false
            continue
        fi
        # Check if the line contains the property we are interested in
        if [[ $line =~ ^.*CollectionChanged.*$ ]]; then
            next_line_contains_name=true
        fi
    done < <(
        dbus-monitor --session "type='signal',interface='org.freedesktop.Secret.Service',member='CollectionChanged',sender='org.freedesktop.secrets',path='/org/freedesktop/secrets'"
    )

    echo "Error: dbus-monitor exited unexpectedly. Cannot insert secrets."
    exit 1
}

# Removes all managed secrets
function removeManagedSecrets {
    echo "Removing previous secrets"
    secret-tool clear home-manager-secret dont-modify-this-manually || true
}

# Store a secret and mark it as managed by home-manager
# Reads the secret from stdin
function storeManagedSecret {
    secret="$(cat)"
    secret_hash="$(echo "$@" "$secret" | sha256sum | cut -f1 -d' ')"
    label="$1"
    shift
    echo "Storing secret \"$label\""
    echo -n "$secret" | secret-tool store home-manager-secret dont-modify-this-manually home-manager-secret-hash "$secret_hash" --label="$label" "$@"
}
