# Visible Photo Title Validation Design

## Problem

Photo titles are used as both card headings and image alternative text. The
existing `trim()`-based presence check accepts strings made only from Unicode
format characters or combining marks, so malformed API data can create a card
whose heading and image alternative are effectively blank.

## Options

1. Keep whitespace-only validation. This preserves the blank-card bug.
2. Remove every format and mark character. This can damage valid emoji and
   decomposed writing systems.
3. Require at least one Unicode letter, number, punctuation mark, or symbol,
   while preserving accepted title bytes for rendering.

## Decision

Use option 3. Reject only titles without a visible base character. Preserve
valid combining marks attached to visible text and emoji sequences containing
format characters such as zero-width joiners.

## Scope

Do not rewrite accepted titles beyond the existing trim, change photo IDs or
thumbnail validation, filter malformed records, or redesign the error state.
