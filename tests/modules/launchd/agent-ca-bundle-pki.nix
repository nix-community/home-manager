{
  _module.args.darwinConfig.security.pki.environment.NIX_SSL_CERT_FILE =
    "/certs/company's $bundle.pem";

  launchd.agents.ca-pki = {
    enable = true;
    config.ProgramArguments = [ "/usr/bin/env" ];
  };

  nmt.script = ''
    plist=LaunchAgents/org.nix-community.home.ca-pki.plist
    assertFileExists "$plist"
    wrapper=$(sed -n 's|.*exec /bin/sh \(/nix/store/[^ ]*-launchd-certificate-environment\) .*|\1|p' "$TESTED/$plist")
    assertFileContent "$wrapper" ${./expected-ca-environment.sh}
  '';
}
