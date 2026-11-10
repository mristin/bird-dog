#!/usr/bin/env python3

"""
Collect the translatable messages of the game into translations/messages.pot,
and update the translations (translations/<language>.po) with them.

The messages come from the ``tr("...")`` and ``tr("...", "context")`` calls in
the GDScripts, and from the translatable fields of the data resources in
data/ (e.g., the titles and the summaries of the missions). A comment line
starting with ``# TRANSLATORS:`` right above a call is passed on to the
translators.

The existing translations are kept. A new message gets an empty translation,
and a message which is not used any more is marked as obsolete. With --check,
nothing is written and the script fails if the files are out of date.
"""

import argparse
import json
import pathlib
import re
import sys
from typing import Dict, List, Optional, Tuple

import polib

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent.parent

TRANSLATIONS_DIR = REPO_ROOT / "translations"

SOURCE_LANGUAGE = "en"


def _read_languages() -> List[str]:
    """Read the codes of the languages besides the source language (English)."""
    path = TRANSLATIONS_DIR / "languages.json"
    codes = [language["code"] for language in json.loads(path.read_text(encoding="utf-8"))]
    return [code for code in codes if code != SOURCE_LANGUAGE]


#: The languages besides English, from translations/languages.json, which lists
#: every language of the game. A new language needs only a new entry there; this
#: script then creates its .po file.
LANGUAGES = _read_languages()

_STRING = r'"((?:[^"\\]|\\.)*)"'
#: A call of ``tr`` or of a wrapper which passes its literal on to ``tr``,
#: e.g., ``_said("Ready!")`` in the captain creator (which picks the gender of
#: that one captain).
TR_RE = re.compile(
    r"\b(?:tr|_said)\(\s*" + _STRING + r"(?:\s*,\s*" + _STRING + r")?\s*\)", re.DOTALL
)

#: A line of a mission with a literal text, e.g., MissionRun.line("Thank you!"),
#: which is translated when it is shown.
LINE_RE = re.compile(r"\bMissionRun\.line\(\s*" + _STRING, re.DOTALL)

TRANSLATORS_RE = re.compile(r"#\s*TRANSLATORS:\s*(.*)$")

#: The translatable fields of the data resources (the missions and the world)
#: and what they are, for the translators.
DATA_FIELDS = {
    "title": "the title of a mission, on its card",
    "summary": "the summary of a mission, one or two short sentences",
    "fun_fact": "a fun fact at the end of a mission, at most three sentences",
    "name": "a name (of a port, a person, a power, a boat or a thing)",
    "role": "what a person does, under their name",
    "phrase": "a noun phrase in a clue, e.g., 'the town with the great Roman arena'",
    "lines": "a line which a person says, at most two short sentences",
    "thanks": "a line of thanks, at most two short sentences",
    "question": "what the crew asks, or what the crew is asked",
    "found_line": "a line in the last port of a trail",
    "wrong_line": "a line after a wrong pick",
    "right_line": "a line after the right pick",
    "objective": "the objective while sailing, on the banner",
    "go_label": "the label of a button",
    "clue_templates": "a clue; {fact} is a noun phrase like 'the town with the great Roman arena'",
    "hallmark_template": "a clue; {hallmark} is a noun phrase like 'a patched red sail'",
    "ask_objective": "the objective while sailing, on the banner; {person} and {port} are names",
    "bring_objective": "the objective while sailing, on the banner; {item}, {person}, {port}",
    "ask_lines": "what a person in a chain of trades wants, at most two short sentences",
    "thanks_lines": "what a person says after a trade, at most two short sentences",
    "intro": "what a judge says before the questions, at most two short sentences",
    "answers": "an answer on a button, a few words",
    "right_lines": "what a judge says after the right answers, at most two short sentences",
    "victory_title": "the headline of the screen at the end of a mission, a few words",
    "victory_lines": "what the crew achieved, on the screen at the end of a mission, one sentence",
    "reward": "what the crew gets from now on, at the end of a mission, one sentence",
    "description": "what a booster or a ship does, on its card, one short sentence",
    "rival_line": "what the crew hears when a rival was first in a port; {port} is a port",
    "fled_line": "what the crew hears when the target slipped away after a wrong pick",
}

#: A text field of a resource: a single string, or an array of strings.
DATA_FIELD_RE = re.compile(r"^(" + "|".join(DATA_FIELDS) + r") = (.*)$", re.MULTILINE)

#: The default of a text field in a script, which the .tres files leave out.
DEFAULT_FIELD_RE = re.compile(
    r"^@export(?:_multiline)? var (" + "|".join(DATA_FIELDS) + r") := " + _STRING + r"$",
    re.MULTILINE,
)

_QUOTED_RE = re.compile(_STRING)

#: (context, message id)
Key = Tuple[str, str]


def _unescape(text: str) -> str:
    return text.encode("utf-8").decode("unicode_escape").encode("latin-1").decode("utf-8")


def _add(
    entries: Dict[Key, polib.POEntry],
    msgid: str,
    context: str,
    relative: str,
    comment: Optional[str],
) -> None:
    key = (context, msgid)
    entry = entries.get(key)
    if entry is None:
        entry = polib.POEntry(msgid=msgid, msgstr="")
        if context:
            entry.msgctxt = context
        entries[key] = entry
    # NOTE (mristin):
    # We record only the file, not the line, so that the translation files do
    # not change whenever the code moves.
    if (relative, "") not in entry.occurrences:
        entry.occurrences.append((relative, ""))
    if comment and comment not in (entry.comment or ""):
        entry.comment = (entry.comment + "\n" if entry.comment else "") + comment


def collect_messages() -> Dict[Key, polib.POEntry]:
    """Collect the messages of all the GDScripts and the data, in a stable order."""
    entries: Dict[Key, polib.POEntry] = {}
    for path in sorted((REPO_ROOT / "scenes").rglob("*.gd")):
        text = path.read_text(encoding="utf-8")
        relative = path.relative_to(REPO_ROOT).as_posix()
        lines = text.splitlines()

        found = [(m.start(), m.group(1), m.group(2), None) for m in TR_RE.finditer(text)]
        found += [(m.start(), m.group(1), None, None) for m in LINE_RE.finditer(text)]
        found += [
            (m.start(), m.group(2), None, DATA_FIELDS[m.group(1)])
            for m in DEFAULT_FIELD_RE.finditer(text)
        ]
        for start, raw_msgid, raw_context, field_comment in sorted(found, key=lambda f: f[0]):
            msgid = _unescape(raw_msgid)
            if msgid == "":
                continue
            context = _unescape(raw_context) if raw_context is not None else ""
            line = text.count("\n", 0, start) + 1

            comment = field_comment
            for previous in reversed(lines[: line - 1]):
                translators = TRANSLATORS_RE.search(previous.strip())
                if translators:
                    comment = translators.group(1)
                    break
                if previous.strip() and not previous.strip().startswith("#"):
                    break

            _add(entries, msgid, context, relative, comment)

    for path in sorted((REPO_ROOT / "data").rglob("*.tres")):
        text = path.read_text(encoding="utf-8")
        relative = path.relative_to(REPO_ROOT).as_posix()
        for match in DATA_FIELD_RE.finditer(text):
            for quoted in _QUOTED_RE.finditer(match.group(2)):
                msgid = _unescape(quoted.group(1))
                if msgid != "":
                    _add(entries, msgid, "", relative, DATA_FIELDS[match.group(1)])

    return entries


#: The grammatical forms which the translations may ask for (see
#: scenes/languages/grammar.gd): the kind of the inserted value, where its
#: messages come from (the folder and the field), and the contexts. A form
#: carries its preposition, since it differs between the places ("в город",
#: but "на остров"; "u Zadar", but "na Hvar").
FORMS = {
    "port": ("data/world/ports", "name", ["to", "in"]),
    "fact": ("data/world/ports", "phrase", ["to", "about"]),
    "item": ("data/world/items", "name", ["acc"]),
    "hallmark": ("data/world/hallmarks", "phrase", ["acc"]),
    "name": (["data/world/decorations", "data/world/ships"], "name", ["acc"]),
}

FORM_EXAMPLES = {
    "to": "where to, with the preposition, e.g. 'в Пулу', 'на Хвар', 'u Pulu', 'na Hvar'",
    "in": "where, with the preposition, e.g. 'в Пуле', 'на Хваре', 'u Puli', 'na Hvaru'",
    "about": "about what, with the preposition, e.g. 'про город ...', 'o gradu ...'",
    "acc": "the accusative, e.g. 'бочку вина', 'bačvu vina'",
}


def collect_forms(entries: Dict[Key, polib.POEntry]) -> None:
    """Add the grammatical forms of the names and the phrases (see FORMS)."""
    for kind, (folders, field, contexts) in FORMS.items():
        field_re = re.compile(r"^" + field + r" = " + _STRING + r"$", re.MULTILINE)
        if isinstance(folders, str):
            folders = [folders]
        paths = [
            path for folder in folders for path in sorted((REPO_ROOT / folder).rglob("*.tres"))
        ]
        for path in paths:
            text = path.read_text(encoding="utf-8")
            relative = path.relative_to(REPO_ROOT).as_posix()
            for match in field_re.finditer(text):
                msgid = _unescape(match.group(1))
                for context in contexts:
                    comment = (
                        f"the form of the {kind} for {{{kind}@{context}}} in the translations: "
                        f"{FORM_EXAMPLES[context]}; empty keeps the plain {kind}"
                    )
                    _add(entries, msgid, context, relative, comment)


def _key(entry: polib.POEntry) -> Key:
    return (entry.msgctxt or "", entry.msgid)


def make_template(entries: Dict[Key, polib.POEntry]) -> polib.POFile:
    template = polib.POFile(wrapwidth=100)
    template.metadata = {
        "Project-Id-Version": "Bird Dog",
        "MIME-Version": "1.0",
        "Content-Type": "text/plain; charset=UTF-8",
        "Content-Transfer-Encoding": "8bit",
    }
    for entry in entries.values():
        template.append(entry)
    return template


def merge(template: polib.POFile, existing: Optional[polib.POFile], language: str) -> polib.POFile:
    """Make the translation of the template, keeping the existing translations."""
    old: Dict[Key, polib.POEntry] = {}
    if existing is not None:
        old = {_key(entry): entry for entry in existing}

    result = polib.POFile(wrapwidth=100)
    result.metadata = dict(template.metadata)
    result.metadata["Language"] = language
    if existing is not None:
        for name in ("Last-Translator", "Language-Team", "Plural-Forms"):
            if name in existing.metadata:
                result.metadata[name] = existing.metadata[name]

    used = set()
    for entry in template:
        merged = polib.POEntry(
            msgid=entry.msgid,
            msgctxt=entry.msgctxt,
            msgstr="",
            occurrences=list(entry.occurrences),
            comment=entry.comment,
        )
        previous = old.get(_key(entry))
        if previous is not None:
            used.add(_key(entry))
            merged.msgstr = previous.msgstr
            merged.flags = [flag for flag in previous.flags if flag != "obsolete"]
            merged.tcomment = previous.tcomment
        result.append(merged)

    # NOTE (mristin):
    # We keep the unused translations as obsolete, so that a message which comes
    # back does not have to be translated again.
    for key, previous in old.items():
        if key not in used and previous.msgstr:
            previous.obsolete = True
            result.append(previous)

    return result


def _render(po: polib.POFile) -> str:
    return str(po)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check",
        action="store_true",
        help="Do not write anything; fail if the translation files are out of date.",
    )
    args = parser.parse_args()

    entries = collect_messages()
    collect_forms(entries)
    template = make_template(entries)

    outputs: List[Tuple[pathlib.Path, str]] = [
        (TRANSLATIONS_DIR / "messages.pot", _render(template))
    ]
    for language in LANGUAGES:
        path = TRANSLATIONS_DIR / f"{language}.po"
        existing = polib.pofile(str(path), wrapwidth=100) if path.exists() else None
        outputs.append((path, _render(merge(template, existing, language))))

    stale = [path for path, text in outputs if not path.exists() or path.read_text("utf-8") != text]
    if args.check:
        for path in stale:
            print(
                f"{path.relative_to(REPO_ROOT)} is out of date; "
                f"run dev/translations/extract.py",
                file=sys.stderr,
            )
        return 1 if stale else 0

    TRANSLATIONS_DIR.mkdir(exist_ok=True)
    for path, text in outputs:
        if path in stale:
            path.write_text(text, encoding="utf-8")
            print(f"Wrote {path.relative_to(REPO_ROOT)}")
    print(f"{len(template)} message(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
