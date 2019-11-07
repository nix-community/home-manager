{ runCommand, lib, bash, coreutils, findutils, gnused, less}:

runCommand
  "home-manager"
  {
    preferLocalBuild = true;
    allowSubstitutes = false;
    meta = with lib; {
      description = "A user environment configurator";
      maintainers = [ maintainers.rycee ];
      platforms = platforms.unix;
      license = licenses.mit;
    };
  }
  ''
    install -v -D -m755  ${./home-manager} $out/bin/home-manager

    substituteInPlace $out/bin/home-manager \
      --subst-var-by bash "${bash}" \
      --subst-var-by coreutils "${coreutils}" \
      --subst-var-by findutils "${findutils}" \
      --subst-var-by gnused "${gnused}" \
      --subst-var-by less "${less}" \

    install -D -m755 ${./completion.bash} \
      $out/share/bash-completion/completions/home-manager
  ''
