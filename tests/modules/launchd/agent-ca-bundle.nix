{ pkgs, realPkgs, ... }:
let
  command = [ "${realPkgs.coreutils}/bin/env" ];
in
{
  _module.args.darwinConfig.environment.variables.NIX_SSL_CERT_FILE = "/certs/company's $bundle.pem";

  launchd.agents = {
    ca-inline = {
      enable = true;
      config.ProgramArguments = command;
    };
    ca-launcher = {
      enable = true;
      waitForNixStore = false;
      config.ProgramArguments = command;
    };
    ca-fish = {
      enable = true;
      waitForNixStore = false;
      launcher.shell = "${pkgs.fish}/bin/fish";
      config.ProgramArguments = command;
    };
    ca-explicit = {
      enable = true;
      waitForNixStore = false;
      config = {
        ProgramArguments = command;
        EnvironmentVariables.SSL_CERT_FILE = "/agent/ssl.pem";
      };
    };
    ca-disabled = {
      enable = false;
      config.ProgramArguments = command;
    };
  };

  nmt.script = ''
    assertFileContent "$(normalizeStorePaths LaunchAgents/org.nix-community.home.ca-inline.plist)" ${./expected-ca-inline.plist}
    assertPathNotExists LaunchAgents/org.nix-community.home.ca-disabled.plist

    launcherFile=LaunchAgents/org.nix-community.home.ca-launcher.plist
    assertFileExists "$launcherFile"
    launcher=$(sed -n 's|.*<string>\(/nix/store/[^<]*/bin/ca-launcher\)</string>.*|\1|p' \
      "$TESTED/$launcherFile")
    assertFileContent "$(normalizeStorePaths "$launcher")" ${./expected-ca-launcher.sh}
    certificateWrapper=$(sed -n 's|^exec /bin/sh \([^ ]*\) .*|\1|p' "$launcher")
    assertFileContent "$certificateWrapper" ${./expected-ca-environment.sh}

    assertFileContent "$(normalizeStorePaths LaunchAgents/org.nix-community.home.ca-explicit.plist)" ${./expected-ca-explicit.plist}
    defaultBundle="/certs/company's \$bundle.pem"

    # The inline launcher's wait4path call is outside the Darwin build sandbox.
    for name in ca-launcher ca-fish; do
      launcherFile=LaunchAgents/org.nix-community.home.$name.plist
      assertFileExists "$launcherFile"
      launcher=$(sed -n "s|.*<string>\(/nix/store/[^<]*/bin/$name\)</string>.*|\1|p" \
        "$TESTED/$launcherFile")
      assertFileIsExecutable "$launcher"
      ${realPkgs.coreutils}/bin/env -i HOME="$PWD" "$launcher" > environment \
        || fail "$name failed with unset certificate variables"
      sed -n '/^NIX_SSL_CERT_FILE=/p; /^SSL_CERT_FILE=/p' environment > certificates.actual
      printf 'NIX_SSL_CERT_FILE=%s\n' "$defaultBundle" > certificates.expected
      assertFileContent "$PWD/certificates.actual" "$PWD/certificates.expected"

      for assignment in NIX_SSL_CERT_FILE=/custom/nix.pem SSL_CERT_FILE=/custom/ssl.pem \
        NIX_SSL_CERT_FILE= SSL_CERT_FILE=; do
        ${realPkgs.coreutils}/bin/env -i HOME="$PWD" "$assignment" "$launcher" > environment \
          || fail "$name failed with $assignment"
        sed -n '/^NIX_SSL_CERT_FILE=/p; /^SSL_CERT_FILE=/p' environment > certificates.actual
        printf '%s\n' "$assignment" > certificates.expected
        assertFileContent "$PWD/certificates.actual" "$PWD/certificates.expected"
      done

      ${realPkgs.coreutils}/bin/env -i HOME="$PWD" \
        NIX_SSL_CERT_FILE=/custom/nix.pem SSL_CERT_FILE=/custom/ssl.pem \
        "$launcher" > environment || fail "$name failed with both certificate variables"
      assertFileContains "$PWD/environment" 'NIX_SSL_CERT_FILE=/custom/nix.pem'
      assertFileContains "$PWD/environment" 'SSL_CERT_FILE=/custom/ssl.pem'
    done
  '';
}
