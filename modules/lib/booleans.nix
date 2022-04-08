{ lib }: {
  # Converts a boolean to a yes/no string. This is used in lots of
  # configuration formats.
  yesNo = value: if value then "yes" else "no";
}
