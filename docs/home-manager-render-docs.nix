{ buildPythonApplication, lib, python, nixos-render-docs }:
buildPythonApplication {
  pname = "home-manager-render-docs";
  version = "0.0";
  format = "pyproject";

  src = lib.cleanSourceWith {
    filter = name: type:
      lib.cleanSourceFilter name type && !(type == "directory"
        && builtins.elem (baseNameOf name) [
          ".pytest_cache"
          ".mypy_cache"
          "__pycache__"
        ]);
    src = ./home-manager-render-docs;
  };

  nativeBuildInputs = with python.pkgs; [ setuptools ];

  propagatedBuildInputs = [ nixos-render-docs ];

  meta = with lib; {
    description = "Renderer for home-manager manual and option docs";
    license = licenses.mit;
    maintainers = [ ];
  };
}
