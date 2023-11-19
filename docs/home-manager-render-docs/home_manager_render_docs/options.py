import argparse
import json
from nixos_render_docs.options import (
    DocBookConverter,
    ManpageConverter,
    CommonMarkConverter,
    AsciiDocConverter,
    _build_cli_db,
    _build_cli_manpage,
    _build_cli_asciidoc,
    _build_cli_commonmark,
)
from nixos_render_docs.manpage import man_escape
from nixos_render_docs.md import md_escape

class HomeManagerManpageConverter(ManpageConverter):

    def finalize(self) -> str:
        result = []

        # TODO: Update header and footer
        result += [
            r'''.TH "HOME-CONFIGURATION\&.NIX" "5" "01/01/1980" "Home Manager"''',
            r'''.\" disable hyphenation''',
            r'''.nh''',
            r'''.\" disable justification (adjust text to left margin only)''',
            r'''.ad l''',
            r'''.\" enable line breaks after slashes''',
            r'''.cflags 4 /''',
            r'''.SH "NAME"''',
            self._render('{file}`home-configuration.nix` - Home Manager configuration specification'),
            r'''.SH "DESCRIPTION"''',
            r'''.PP''',
            self._render('The file {file}`~/.config/home-manager/home.nix` contains the '
                        'declarative specification of your Home Manager configuration. '
                        'The command {command}`home-manager` takes this file and '
                        'realises the user environment configuration specified therein.'),
            r'''.SH "OPTIONS"''',
            r'''.PP''',
            self._render('You can use the following options in {file}`home-configuration.nix`.'),
        ]

        for (name, opt) in self._sorted_options():
            result += [
                ".PP",
                f"\\fB{man_escape(name)}\\fR",
                ".RS 4",
            ]
            result += opt.lines
            if links := opt.links:
                result.append(self.__option_block_separator__)
                md_links = ""
                for i in range(0, len(links)):
                    md_links += "\n" if i > 0 else ""
                    if links[i].startswith('#opt-'):
                        md_links += f"{i+1}. see the {{option}}`{self._options_by_id[links[i]]}` option"
                    else:
                        md_links += f"{i+1}. " + md_escape(links[i])
                result.append(self._render(md_links))

            result.append(".RE")

        result += [
            r'''.SH "AUTHORS"''',
            r'''.PP''',
            r'''Home Manager contributors''',
        ]

        return "\n".join(result)


def _run_cli_db(args: argparse.Namespace) -> None:
    with open(args.manpage_urls, 'r') as manpage_urls:
        md = DocBookConverter(
            json.load(manpage_urls),
            revision = args.revision,
            document_type = args.document_type,
            varlist_id = args.varlist_id,
            id_prefix = args.id_prefix)

        with open(args.infile, 'r') as f:
            md.add_options(json.load(f))
        with open(args.outfile, 'w') as f:
            f.write(md.finalize())

def _run_cli_manpage(args: argparse.Namespace) -> None:
    md = HomeManagerManpageConverter(revision = args.revision)

    with open(args.infile, 'r') as f:
        md.add_options(json.load(f))
    with open(args.outfile, 'w') as f:
        f.write(md.finalize())

def _run_cli_commonmark(args: argparse.Namespace) -> None:
    with open(args.manpage_urls, 'r') as manpage_urls:
        md = CommonMarkConverter(json.load(manpage_urls), revision = args.revision)

        with open(args.infile, 'r') as f:
            md.add_options(json.load(f))
        with open(args.outfile, 'w') as f:
            f.write(md.finalize())

def _run_cli_asciidoc(args: argparse.Namespace) -> None:
    with open(args.manpage_urls, 'r') as manpage_urls:
        md = AsciiDocConverter(json.load(manpage_urls), revision = args.revision)

        with open(args.infile, 'r') as f:
            md.add_options(json.load(f))
        with open(args.outfile, 'w') as f:
            f.write(md.finalize())

def build_cli(p: argparse.ArgumentParser) -> None:
    formats = p.add_subparsers(dest='format', required=True)
    _build_cli_db(formats.add_parser('docbook'))
    _build_cli_manpage(formats.add_parser('manpage'))
    _build_cli_commonmark(formats.add_parser('commonmark'))
    _build_cli_asciidoc(formats.add_parser('asciidoc'))

def run_cli(args: argparse.Namespace) -> None:
    if args.format == 'docbook':
        _run_cli_db(args)
    elif args.format == 'manpage':
        _run_cli_manpage(args)
    elif args.format == 'commonmark':
        _run_cli_commonmark(args)
    elif args.format == 'asciidoc':
        _run_cli_asciidoc(args)
    else:
        raise RuntimeError('format not hooked up', args)
