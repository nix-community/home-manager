{ lib, pkgs, ... }:
let
  darwinConfig =
    (lib.evalModules {
      specialArgs = {
        inherit pkgs;
        _class = "darwin";
      };

      modules = [
        ../../../nix-darwin
        (_: {
          options.users.users = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.submodule (
                { name, ... }:
                {
                  options = {
                    name = lib.mkOption {
                      type = lib.types.str;
                      default = name;
                    };
                    home = lib.mkOption { type = lib.types.str; };
                    uid = lib.mkOption { type = lib.types.int; };
                    packages = lib.mkOption {
                      type = lib.types.listOf lib.types.package;
                      default = [ ];
                    };
                  };
                }
              )
            );
            default = { };
          };

          options.environment.pathsToLink = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };

          options.system.activationScripts = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.submodule (_: {
                options.text = lib.mkOption {
                  type = lib.types.lines;
                  default = "";
                };
              })
            );
            default = { };
          };

          options.nix.enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
          };

          options.nix.package = lib.mkOption {
            type = lib.types.package;
            default = pkgs.nix;
          };

          options.warnings = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };

          options.assertions = lib.mkOption {
            type = lib.types.listOf (
              lib.types.submodule (_: {
                options.assertion = lib.mkOption { type = lib.types.bool; };
                options.message = lib.mkOption { type = lib.types.str; };
              })
            );
            default = [ ];
          };

          config = {
            home-manager.useUserPackages = true;

            users.users.alice.home = "/Users/alice";

            home-manager.users.alice = {
              home.stateVersion = "24.11";
              programs.fish.enable = true;
            };
          };
        })
      ];
    }).config;

  expectedNixProfiles = "/nix/var/nix/profiles/default /etc/profiles/per-user/alice";
  devenvCompletion = "${pkgs.devenv}/share/fish/vendor_completions.d/devenv.fish";
  activationScriptContent = builtins.readFile "${darwinConfig.home-manager.users.alice.home.activationPackage}/activate";
  activationScriptSetsNixProfiles = lib.hasInfix "launchctl setenv NIX_PROFILES '${expectedNixProfiles}'" activationScriptContent;
  activationScriptMentionsXdgDataDirs = lib.hasInfix "XDG_DATA_DIRS" activationScriptContent;
  sessionVariablesSetXdgDataDirs = builtins.hasAttr "XDG_DATA_DIRS" darwinConfig.home-manager.users.alice.home.sessionVariables;
in
{
  test.stubs.devenv = {
    outPath = null;
    buildScript = ''
      mkdir -p "$out/bin" "$out/share/fish/vendor_completions.d"
      touch "$out/bin/devenv"
      chmod +x "$out/bin/devenv"
      cat > "$out/share/fish/vendor_completions.d/devenv.fish" <<'EOF'
      complete -c devenv -f
      complete -c devenv -a init
      EOF
    '';
  };

  nmt.script = ''
    test "${builtins.toJSON activationScriptSetsNixProfiles}" = 'true'
    test "${builtins.toJSON activationScriptMentionsXdgDataDirs}" = 'false'
    test "${builtins.toJSON sessionVariablesSetXdgDataDirs}" = 'false'

    testHome="$(mktemp -d)"
    trap 'rm -rf "$testHome"' EXIT

    mkdir -p "$testHome/.config/fish"
    cp ${darwinConfig.home-manager.users.alice.home.activationPackage}/home-files/.config/fish/config.fish \
      "$testHome/.config/fish/config.fish"

    mkdir -p "$testHome/work"
    mkdir -p "$testHome/wrong-profile/share/fish/vendor_completions.d"
    mkdir -p "$testHome/correct-profile/share/fish/vendor_completions.d"
    cp ${devenvCompletion} "$testHome/correct-profile/share/fish/vendor_completions.d/devenv.fish"

    cd "$testHome/work"

    env -i \
      HOME="$testHome" \
      USER=alice \
      PATH="${
        lib.makeBinPath [
          pkgs.coreutils
          pkgs.fish
          pkgs.gnugrep
          pkgs.devenv
        ]
      }" \
      NIX_PROFILES='${expectedNixProfiles}' \
      ${pkgs.fish}/bin/fish -ic 'printf "%s\n" $fish_complete_path' > "$testHome/fish_complete_path"

    test "$(${pkgs.gnugrep}/bin/grep -Fxc '/etc/profiles/per-user/alice/share/fish/vendor_completions.d' "$testHome/fish_complete_path")" -eq 1

    env -i \
      HOME="$testHome" \
      USER=alice \
      PATH="${
        lib.makeBinPath [
          pkgs.coreutils
          pkgs.fish
          pkgs.gnugrep
          pkgs.devenv
        ]
      }" \
      NIX_PROFILES="/nix/var/nix/profiles/default $testHome/wrong-profile" \
      ${pkgs.fish}/bin/fish -ic 'complete -C "devenv "' > "$testHome/devenv-before"

    env -i \
      HOME="$testHome" \
      USER=alice \
      PATH="${
        lib.makeBinPath [
          pkgs.coreutils
          pkgs.fish
          pkgs.gnugrep
          pkgs.devenv
        ]
      }" \
      NIX_PROFILES="/nix/var/nix/profiles/default $testHome/correct-profile" \
      ${pkgs.fish}/bin/fish -ic 'printf "%s\n" $fish_complete_path' > "$testHome/fish_complete_path_after"

    env -i \
      HOME="$testHome" \
      USER=alice \
      PATH="${
        lib.makeBinPath [
          pkgs.coreutils
          pkgs.fish
          pkgs.gnugrep
          pkgs.devenv
        ]
      }" \
      NIX_PROFILES="/nix/var/nix/profiles/default $testHome/correct-profile" \
      ${pkgs.fish}/bin/fish -ic 'complete -C "devenv "' > "$testHome/devenv-after"

    test "$(${pkgs.gnugrep}/bin/grep -Fxc "$testHome/correct-profile/share/fish/vendor_completions.d" "$testHome/fish_complete_path_after")" -eq 1
    test "$(${pkgs.gnugrep}/bin/grep -Ec '^init($|[[:space:]])' "$testHome/devenv-before")" -eq 0
    test "$(${pkgs.gnugrep}/bin/grep -Ec '^init($|[[:space:]])' "$testHome/devenv-after")" -eq 1
  '';
}
