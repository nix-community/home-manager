# Mutable copies must not write through symlinked parent directories.
# Unlike home.file links, copies would modify files outside the declared tree.
function checkMutableParents() {
  local relativePath="$1" parent="$HOME" component
  case "/$relativePath/" in
    *"//"* | *"/./"* | *"/../"*)
      errorEcho "Unsafe mutable file target: '$relativePath'."
      return 1
      ;;
  esac
  while [[ "$relativePath" == */* ]]; do
    component="${relativePath%%/*}"
    relativePath="${relativePath#*/}"
    parent+="/$component"
    if [[ -L "$parent" || ( -e "$parent" && ! -d "$parent" ) ]]; then
      errorEcho "Mutable file parent '$parent' must be a directory, not a file or symlink."
      return 1
    fi
  done
}
