def main [name: string, out: string] {
	plugin list
	| where name == $name
	| select name status filename
	| to nuon
	| save --force $out
}
