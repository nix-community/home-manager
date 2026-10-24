{ realPkgs, ... }:
let
  command = [ "${realPkgs.coreutils}/bin/env" ];
in
{
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
  };

  nmt.script = ''
    assertFileContent "$(normalizeStorePaths LaunchAgents/org.nix-community.home.ca-inline.plist)" ${./expected-ca-inline.plist}
    launcherFile=LaunchAgents/org.nix-community.home.ca-launcher.plist
    assertFileExists "$launcherFile"
    launcher=$(sed -n 's|.*<string>\(/nix/store/[^<]*/bin/ca-launcher\)</string>.*|\1|p' \
      "$TESTED/$launcherFile")
    assertFileContent "$(normalizeStorePaths "$launcher")" ${./expected-ca-launcher.sh}
    certificateWrapper=$(sed -n 's|^exec /bin/sh \([^ ]*\) .*|\1|p' "$launcher")
    assertFileContent "$(normalizeStorePaths "$certificateWrapper")" ${./expected-ca-standalone-environment.sh}
    missingBundle=$(sed -n 's|^[[:space:]]*if \([^ ]*\) "$NIX_SSL_CERT_FILE"; then|\1|p' "$certificateWrapper")

    mkdir -p certificates/denied
    printf 'not a valid certificate' > certificates/present.pem
    touch certificates/empty.pem certificates/unreadable.pem certificates/denied/present.pem
    ln -s missing.pem certificates/dangling.pem
    ln -s loop.pem certificates/loop.pem
    chmod 000 certificates/unreadable.pem certificates/denied
    trap 'chmod 700 certificates/denied; chmod 600 certificates/unreadable.pem' EXIT

    for path in missing.pem dangling.pem; do
      "$missingBundle" "$PWD/certificates/$path" || fail "Expected ENOENT for $path"
    done
    for path in present.pem empty.pem unreadable.pem loop.pem \
      present.pem/not-a-directory denied/present.pem denied/missing.pem; do
      status=0
      "$missingBundle" "$PWD/certificates/$path" || status=$?
      [[ $status == 1 ]] || fail "Expected a nonmissing result for $path, got $status"
    done
    chmod 700 certificates/denied
    chmod 600 certificates/unreadable.pem
    trap - EXIT
  '';
}
