#!/usr/bin/env python3

"""
Check the translations in translations/<language>.po.

Report per language how many messages are translated, how many are still to
be reviewed (fuzzy) and how many are missing; list them with --verbose.

Fail on errors which would break the game:

* a translation which drops, adds or misspells a placeholder (``{captain}``),
* a choice for the addressed captains (``{crew|Kapitän|Kapitänin}``, see
  scenes/languages/grammar.gd) with fewer than two or more than four forms,
* a translation which is longer than the limit in its translator comment
  ("at most N characters").
"""

import argparse
import pathlib
import re
import sys
from typing import List

import polib

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent.parent

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

import extract  # noqa: E402  # pylint: disable=wrong-import-position

#: A placeholder, maybe with a grammatical form ("{port@to}", see
#: scenes/languages/grammar.gd); a noun which agrees with a number
#: ("{ducats|дукат|дуката|дукатов}") is not a placeholder of its own.
PLACEHOLDER_RE = re.compile(r"\{([a-z_]+)(?:@[a-z_]+)?\}")
AGREEMENT_RE = re.compile(r"\{([a-z_]+)\|[^{}]*\}")

#: A choice of the forms for the addressed captains: one haiduk, one
#: haidukess, several captains, several haidukesses (the last two optional).
CREW_RE = re.compile(r"\{crew\|([^{}]*)\}")
LIMIT_RE = re.compile(r"at most (\d+) characters")


def _where(entry: polib.POEntry) -> str:
    if entry.occurrences:
        path, line = entry.occurrences[0]
        return f"{path}:{line}" if line else path
    return "?"


def check(language: str, verbose: bool) -> List[str]:
    """Check one language and return the errors."""
    path = extract.TRANSLATIONS_DIR / f"{language}.po"
    if not path.exists():
        return [f"{path.relative_to(REPO_ROOT)} is missing; run dev/translations/extract.py"]

    po = polib.pofile(str(path))
    errors: List[str] = []
    missing: List[polib.POEntry] = []
    fuzzy: List[polib.POEntry] = []
    done = 0

    for entry in po:
        if entry.obsolete:
            continue
        if not entry.msgstr:
            missing.append(entry)
            continue
        if "fuzzy" in entry.flags:
            fuzzy.append(entry)
        else:
            done += 1

        expected = sorted(PLACEHOLDER_RE.findall(entry.msgid))
        found = sorted(PLACEHOLDER_RE.findall(entry.msgstr))
        for forms in CREW_RE.findall(entry.msgstr):
            count = len(forms.split("|"))
            if not 2 <= count <= 4:
                errors.append(
                    f"{language}: {_where(entry)}: the choice {{crew|{forms}}} has {count} "
                    "form(s), but needs 2 to 4 (haiduk, haidukess, several, several haidukesses)"
                )
        for agreed in AGREEMENT_RE.findall(entry.msgstr):
            if agreed == "crew":
                continue
            if agreed not in expected:
                errors.append(
                    f"{language}: {_where(entry)}: the noun agrees with {{{agreed}}}, "
                    f"which {entry.msgid!r} does not have"
                )
        if expected != found:
            errors.append(
                f"{language}: {_where(entry)}: the placeholders {found} of the translation "
                f"do not match {expected} of {entry.msgid!r}"
            )

        limit = LIMIT_RE.search(entry.comment or "")
        # NOTE (mristin):
        # The longest form of every choice for the addressed captains must fit.
        shown = CREW_RE.sub(lambda m: max(m.group(1).split("|"), key=len), entry.msgstr)
        if limit and len(shown) > int(limit.group(1)):
            errors.append(
                f"{language}: {_where(entry)}: the translation is {len(shown)} characters "
                f"long, but at most {limit.group(1)} fit: {shown!r}"
            )

    total = done + len(fuzzy) + len(missing)
    print(
        f"{language}: {done}/{total} translated and reviewed, "
        f"{len(fuzzy)} to review (fuzzy), {len(missing)} missing"
    )
    if verbose:
        for title, entries in (("to review", fuzzy), ("missing", missing)):
            for entry in entries:
                print(f"  {title}: {_where(entry)}: {entry.msgid!r}")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--verbose", action="store_true", help="List the open messages.")
    args = parser.parse_args()

    errors: List[str] = []
    for language in extract.LANGUAGES:
        errors.extend(check(language, args.verbose))

    for error in errors:
        print(error, file=sys.stderr)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
