def localIdentity:
  gsub("^\\s+|\\s+$"; "")
  | (if . == "~" then $homeDirectory
     elif startswith("~/") then $homeDirectory + .[1:]
     elif startswith("file://") then
       capture("^file://(?<host>[^/?#]*)(?<path>/[^?#]*)?(?:[?#].*)?$")
       | if (.host | ascii_downcase) == "localhost" or .host == "" then
           (.path // "/")
           | if test("%(2[fF]|00)") or (gsub("%[0-9a-fA-F]{2}"; "") | contains("%")) then
               error("Unsupported Pi file URL")
             else @urid end
         else error("Unsupported Pi file URL host") end
     else . end) as $path
  | (if $path | startswith("/") then $path
     else $configDir + "/" + $path end)
  | split("/")
  | reduce .[] as $part ([];
      if $part == "" or $part == "." then .
      elif $part == ".." then .[:-1]
      else . + [$part] end)
  | "local:/" + join("/");
def packageIdentity:
  (if type == "string" then .
   elif type == "object" and (.source | type == "string") then .source
   else error("Invalid Pi package entry") end) as $source
  | if $source | startswith("npm:") then
      "npm:" + ($source[4:] | gsub("^\\s+|\\s+$"; "")
        | capture("^(?<name>@?[^@]+(?:/[^@]+)?)(?:@.+)?$").name)
    elif ($source | test("^\\s*(git:|https?://|ssh://)")) then
      ($source | gsub("^\\s+|\\s+$"; "") | if test("^git://") then . else ltrimstr("git:") end
        | gsub("^\\s+|\\s+$"; "")) as $url
      | (if $url | test("^(https?|ssh|git)://") then
           $url | capture("^(?<protocol>https?|ssh|git)://(?:[^@/]+@)?(?<host>[^/:]+)(?::[0-9]+)?/+(?<path>[^@#?]+)(?:[@#].+)?$")
           | if .protocol == "http" or .protocol == "https" then
               .host |= ascii_downcase
             else . end
         elif $url | startswith("git@") then
           $url | capture("^git@(?<host>[^:]+):(?<path>[^@#]+)(?:[@#].+)?$")
         elif $url | test("^(github|gitlab|bitbucket):") then
           $url | capture("^(?<host>github|gitlab|bitbucket):(?<path>[^@#]+)(?:[@#].+)?$")
           | .host += (if .host == "bitbucket" then ".org" else ".com" end)
         elif $url | test("^[^/:]+/[^/]+(?:[@#].+)?$") then
           {host: "github.com", path: $url}
         else
           $url | capture("^(?<host>[^/:]+[.][^/:]+|localhost)/(?<path>[^@#]+)(?:[@#].+)?$")
         end)
      | if .host == "github.com" then
          .path |= (sub("^(?<repo>[^/]+/[^/]+)/tree(?:/.*)?$"; "\(.repo)") | sub("/+$"; ""))
        else . end
      | .path |= (sub("[@#].*$"; "") | sub("\\.git$"; ""))
      | if (.path | test("^[^/%\\\\]+/[^%\\\\]+$"))
           and (.path | split("/") | all(. != "..")) then
          "git:" + .host + "/" + .path
        else error("Unsupported Pi Git source") end
    else $source | localIdentity end;
def checkedIdentity:
  [packageIdentity] | if length == 1 then .[0]
    else error("Unsupported Pi package source") end;
$dynamic * $static
| if $static | has("packages") then
    .packages = (
      reduce ($dynamic.packages // [])[] as $package
        ([]; ($package | checkedIdentity) as $identity
          | if any(.[]; checkedIdentity == $identity) then .
            else . + [$package] end)
      | reduce $static.packages[] as $package
          (.; ($package | checkedIdentity) as $identity
            | if any(.[]; checkedIdentity == $identity) then
                map(if checkedIdentity == $identity then $package else . end)
              else . + [$package] end))
  else . end
