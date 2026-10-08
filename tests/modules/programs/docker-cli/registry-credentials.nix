{
  config,
  lib,
  pkgs,
  realPkgs,
  ...
}:

{
  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

  programs.docker-cli = {
    enable = true;

    configDir = ".docker2";

    settings.proxies.default.httpProxy = "http://proxy.example.org:3128";

    registryCredentials."https://index.docker.io/v1/" = {
      username = "caniko";
      passwordFile = "/@TMPDIR@/docker-token";
    };
    registryCredentials."registry.example.org" = {
      username = "caniko";
      passwordFile = "/@TMPDIR@/second-token";
    };
  };

  nmt.script =
    let
      cfgDocker = config.programs.docker-cli;
      activationScript = pkgs.writeScript "activation" config.home.activation.dockerCliRegistryCredentials.data;
      configTestPath = "$HOME/${cfgDocker.configDir}/config.json";
    in
    ''
      export HOME=$TMPDIR/hm-user
      echo -n s3cr3t > $TMPDIR/docker-token
      echo -n s3cr3t > $TMPDIR/second-token

      assertPathNotExists home-files/${cfgDocker.configDir}/config.json

      substitute ${activationScript} $TMPDIR/activate --subst-var TMPDIR
      chmod +x $TMPDIR/activate
      # Capture jq's actual argv without recording stdin or credential files.
      cat > $TMPDIR/jq-wrapper <<'EOF'
      #!${realPkgs.runtimeShell}
      printf '%s\n' "$@" >> "$TMPDIR/jq-argv"
      if [[ -v FAIL_JQ ]]; then exit 47; fi
      exec ${realPkgs.jq}/bin/jq "$@"
      EOF
      chmod +x $TMPDIR/jq-wrapper
      substituteInPlace $TMPDIR/activate --replace-fail 'jq \' '"$TMPDIR/jq-wrapper" \'
      $TMPDIR/activate

      assertFileExists ${configTestPath}
      assertFileContent ${configTestPath} \
        ${./registry-credentials.json}
      test "$(${realPkgs.coreutils}/bin/stat -c '%a' ${configTestPath})" = 600

      $TMPDIR/activate
      assertFileContent ${configTestPath} \
        ${./registry-credentials.json}

      if grep -F -e s3cr3t -e Y2FuaWtvOnMzY3IzdA== "$TMPDIR/jq-argv"; then
        fail "Registry credentials were passed as process arguments"
      fi

      cp ${configTestPath} $TMPDIR/saved-config
      rm $TMPDIR/second-token
      if $TMPDIR/activate; then fail "Missing token did not fail activation"; fi
      cmp $TMPDIR/saved-config ${configTestPath}
      test "$(${realPkgs.coreutils}/bin/stat -c '%a' ${configTestPath})" = 600
      echo -n s3cr3t > $TMPDIR/second-token
      if FAIL_JQ=1 $TMPDIR/activate; then fail "jq failure did not fail activation"; fi
      cmp $TMPDIR/saved-config ${configTestPath}

      DRY_RUN=1 $TMPDIR/activate
      cmp $TMPDIR/saved-config ${configTestPath}

      # Failed activation must clean up its private candidate directory.
      test "$(find "$HOME/${cfgDocker.configDir}" -name 'config.json.*' | wc -l)" -eq 0
    '';
}
