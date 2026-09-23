{ lib }:
{
  file,
  entries,
  backup ? "main",
}:
map (
  entry:
  let
    to = entry.to or "settings";
    files = lib.concatMapStringsSep " and " (path: "`${toString path}'") (
      entry.files or (lib.replicate (entry.definitions or 1) file)
    );
    suffix =
      if entry.changed or false then
        "has been changed to `${to}' that has a different type. Please read `${to}' documentation and update your configuration accordingly."
      else
        "has been renamed to `${to}'.";
  in
  "Borgmatic backup `programs.borgmatic.backups.${backup}`: The option `${entry.from}' defined in ${files} ${suffix}"
) entries
