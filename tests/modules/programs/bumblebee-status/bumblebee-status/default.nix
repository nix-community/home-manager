{ pkgs, lib, python3, python3Packages, fetchFromGitHub, withPlugins ? null, ...
}:
python3Packages.buildPythonPackage rec {
  pname = "bumblebee-status";
  version = "2.1.6";

  src = fetchFromGitHub {
    owner = "tobi-wan-kenobi";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-Oo7n3NyUxBedQHG5P7TM9nuI2hwnVN1SJcK9OP3yiyE=";
  };

  propagatedBuildInputs = let
    allPlugins = import ./plugins.nix { inherit pkgs python3Packages; };

    isSelected = plugin: builtins.elem plugin.name withPlugins;

    selectedPlugins = lib.filter isSelected allPlugins;

    pluginPropagatedBuildInputs =
      lib.attrsets.catAttrs "requires" selectedPlugins;
  in lib.lists.unique pluginPropagatedBuildInputs;

  checkInputs = with python3Packages; [
    freezegun
    netifaces
    psutil
    pytest
    pytest-mock
  ];

  checkPhase = ''
    runHook preCheck

    # Fixes `locale.Error: unsupported locale setting` in some tests.
    export LOCALE_ARCHIVE="${pkgs.glibcLocales}/lib/locale/locale-archive";

    # FIXME: We skip the `dunst` module tests, some of which fail with
    # `RuntimeError: killall -s SIGUSR2 dunst not found`.
    # This is not solved by adding `pkgs.killall` to `checkInputs`.
    ${python3.interpreter} -m pytest -k 'not test_dunst.py'

    runHook postCheck
  '';

  postInstall = ''
    # Remove binary cache files
    find $out -name "__pycache__" -type d | xargs rm -rv

    # Make themes available for bumblebee-status to detect them
    cp -r ./themes $out/${python3.sitePackages}
  '';

  meta = with lib; {
    description =
      "bumblebee-status is a modular, theme-able status line generator for the i3 window manager.";
    homepage = "https://bumblebee-status.readthedocs.io/";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = with maintainers; [ augustebaum ];
  };
}
