{
  config,
  lib,
  pkgs,
  ...
}:
let
  operation = ../../../../modules/programs/pi-coding-agent-settings-filter.jq;
  target = "custom pi/settings.json";
  identityPackages = [
    {
      source = "npm:plain@2";
      autoload = false;
      extensions = [ "custom.ts" ];
    }
    "npm:@scope/pkg@2"
    "git:ssh://git@github.com/Owner/Repo@new"
    "http://github.com/Owner/Other@new"
    "git:Owner/Third@new"
    "git:github:Owner/Fourth@new"
    "git:git@example.org:Owner/Fifth@new"
    "git:github:Owner/Sixth@new"
    "git:Owner/Seventh@new"
    "https://github.com/Owner/Eighth.git@new"
    "https://github.com/Owner/Ninth.git/@new"
    "git:github.com/Owner/Tenth@new"
    "https://github.com/Owner/Eleventh/tree/new"
    {
      source = "local";
      autoload = false;
    }
    "~/parent"
    "~/./home-package"
    "url package"
    "café"
    "~"
  ];

in
{
  programs.pi-coding-agent = {
    package = null;
    mutableSettings = true;
    configDir = "${config.home.homeDirectory}/custom pi";
    enable = true;
    settings = {
      packages = identityPackages ++ [ "npm:case@2" ];
      enabledModels = [ "managed" ];
      theme = "dark";
    };
  };

  assertions = [
    {
      assertion = !(config.home.file ? "/home/hm-user/custom pi/settings.json");
      message = "Mutable pi-coding-agent settings must not be owned by home.file.";
    }
    {
      assertion = lib.hasInfix "display_path=${lib.escapeShellArg "/home/hm-user/custom pi/settings.json"}\n" config.home.activation.piCodingAgentMutableSettings.data;
      message = "Pi must merge into the configured destination.";
    }
    {
      assertion = config.home.activation ? piCodingAgentMutableSettings;
      message = "Pi must merge only enabled, nonempty settings.";
    }
    {
      assertion = !(builtins.elem pkgs.pi-coding-agent config.home.packages);
      message = "A null Pi package must not be installed.";
    }
    {
      assertion = config.home.activation.piCodingAgentMutableSettings.after == [ "linkGeneration" ];
      message = "Pi must merge after linkGeneration.";
    }
    {
      assertion = lib.hasInfix (builtins.readFile operation) config.home.activation.piCodingAgentMutableSettings.data;
      message = "Pi activation must use the package identity filter tested below.";
    }
    {
      assertion =
        lib.hasInfix ''"/home/hm-user" as $homeDirectory'' config.home.activation.piCodingAgentMutableSettings.data
        && lib.hasInfix ''"/home/hm-user/custom pi" as $configDir'' config.home.activation.piCodingAgentMutableSettings.data;
      message = "Pi activation must bind the home and configuration directories for local package identities.";
    }
  ];
  nmt.script = ''
    assertPathNotExists "home-files/${target}"

    settings="$(grep -m1 -o '/nix/store/[^ ]*-pi-coding-agent-settings.json' "$TESTED/activate")" \
      || fail "Missing pi-coding-agent-settings.json input"
    assertFileContent "$settings" ${./mutable-input.json}
    ${lib.getExe pkgs.jaq} -n --arg homeDirectory "${config.home.homeDirectory}" --arg configDir "${config.programs.pi-coding-agent.configDir}" --argjson dynamic "$(cat ${./mutable-existing.json})" \
      --argjson static "$(cat "$settings")" -f ${operation} > "$TMPDIR/merged.json" \
      || fail "Pi package merge failed"
    assertFileContent "$TMPDIR/merged.json" ${./mutable-expected.json}
    for invalid in ${./mutable-invalid-object.json} ${./mutable-invalid-git.json} ${./mutable-invalid-host.json} ${./mutable-invalid-escape.json}; do
      if ${lib.getExe pkgs.jaq} -n --arg homeDirectory "${config.home.homeDirectory}" --arg configDir "${config.programs.pi-coding-agent.configDir}" --argjson dynamic "$(cat "$invalid")" \
        --argjson static "$(cat "$settings")" -f ${operation} > /dev/null; then
        fail "Invalid Pi package source was accepted"
      fi
    done
  '';
}
