class_name OptionData
extends Resource

## One selectable or draggable item: a tool, a basic need, a multiple-choice
## answer, or a function card.
##
## The artwork carries the item's name in its own pixels (see art/MANIFEST.md),
## so [member label] and [member wrong_hint] are TRANSCRIPTS — they record what
## the art says and are never drawn on screen. They exist so the wording stays
## searchable, reviewable in a diff, and usable as a voice-over script.

@export var id: StringName = &""

## The item's name exactly as drawn in [member icon]. Transcript only.
@export var label: String = ""

## The item card, with its name already drawn on it.
@export var icon: Texture2D

## Used only while [member icon] is null, so the game stays playable before an
## asset is wired up.
@export var placeholder_color: Color = Color(0.45, 0.62, 0.35)

## Shown when this item is chosen for a challenge where it is not the answer.
## One hint per item, not one per (item x challenge) pair — six lines instead of
## twenty-five for Level 2, and it reads correctly everywhere.
@export_multiline var wrong_hint: String = "Oops, let's try again!"

## Voice-over line for this item's name, at res://audio/vo/en/<vo_key>.ogg.
@export var vo_key: StringName = &""
