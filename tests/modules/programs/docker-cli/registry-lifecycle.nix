{
  config,
  lib,
  pkgs,
  realPkgs,
  extendModules,
  ...
}:
let
  generation =
    enabled: credentials:
    let
      evaluated =
        (extendModules {
          modules = [
            {
              programs.docker-cli = {
                enable = lib.mkForce enabled;
                registryCredentials = lib.mkForce credentials;
              };
            }
          ];
        }).config;
      package = pkgs.runCommand "docker-cli-test-generation" { } ''
        mkdir -p "$out"
        ln -s ${evaluated.home-files} "$out/home-files"
        ${evaluated.home.extraBuilderCommands}
      '';
      activate = pkgs.writeShellScript "docker-cli-test-activate" ''
        set -euo pipefail
        ${config.lib.bash.initHomeManagerLib}
        export HOME_MANAGER_BACKUP_COMMAND="''${HOME_MANAGER_BACKUP_COMMAND:-}"
        export HOME_MANAGER_BACKUP_EXT="''${HOME_MANAGER_BACKUP_EXT:-}"
        export HOME_MANAGER_BACKUP_OVERWRITE="''${HOME_MANAGER_BACKUP_OVERWRITE:-}"
        export VERBOSE_ARG=""
        newGenPath=${package}
        oldGenPath="$1"
        ${evaluated.home.activation.checkDockerCliRegistryCredentials.data or ""}
        ${evaluated.home.activation.checkLinkTargets.data}
        ${evaluated.home.activation.linkGeneration.data}
        ${evaluated.home.activation.dockerCliRegistryCredentials.data or ""}
      '';
    in
    {
      inherit package activate;
    };
  credentials."registry.example.org" = {
    username = "example-user";
    passwordFile = "/@TMPDIR@/docker-token";
  };
  plain = generation true { };
  authenticated = generation true credentials;
  disabled = generation false { };
in
{
  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";
  programs.docker-cli = {
    enable = true;
    configDir = ".docker2";
    settings.proxies.default.httpProxy = "http://proxy.example.org:3128";
  };
  nmt.script = ''
    export HOME="$TMPDIR/hm-user"
    export PATH="${
      lib.makeBinPath [
        realPkgs.bash
        realPkgs.gettext
      ]
    }:$PATH"
    substitute ${plain.activate} "$TMPDIR/plain" --subst-var TMPDIR
    substitute ${authenticated.activate} "$TMPDIR/authenticated" --subst-var TMPDIR
    substitute ${disabled.activate} "$TMPDIR/disabled" --subst-var TMPDIR
    chmod +x "$TMPDIR/plain" "$TMPDIR/authenticated" "$TMPDIR/disabled"
    printf fake-token > "$TMPDIR/docker-token"
    "$TMPDIR/plain" ${disabled.package}
    test -L "$HOME/.docker2/config.json"
    "$TMPDIR/authenticated" ${plain.package}
    test ! -L "$HOME/.docker2/config.json"
    cp "$HOME/.docker2/config.json" "$TMPDIR/saved-config"

    # Missing credentials fail before home.file can replace working contents.
    rm "$TMPDIR/docker-token"
    if "$TMPDIR/authenticated" ${authenticated.package}; then
      fail "Missing credentials did not reject activation"
    fi
    cmp "$TMPDIR/saved-config" "$HOME/.docker2/config.json"
    printf fake-token > "$TMPDIR/docker-token"

    # Docker's atomic saves must not break generation-bound ownership.
    printf 'application edits' > "$HOME/.docker2/replacement"
    mv "$HOME/.docker2/replacement" "$HOME/.docker2/config.json"
    "$TMPDIR/plain" ${authenticated.package}
    test -L "$HOME/.docker2/config.json"
    "$TMPDIR/authenticated" ${plain.package}
    "$TMPDIR/disabled" ${authenticated.package}
    test ! -e "$HOME/.docker2/config.json"

    # An unrelated config cannot be adopted just because credentials are on.
    mkdir -p "$HOME/.docker2"
    printf unmanaged > "$HOME/.docker2/config.json"
    if "$TMPDIR/authenticated" ${disabled.package}; then
      fail "Docker credentials silently adopted an unmanaged file"
    fi
    test "$(cat "$HOME/.docker2/config.json")" = unmanaged
  '';
}
