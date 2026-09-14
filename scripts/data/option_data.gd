class_name OptionData
extends Resource

## One selectable / draggable item shown to the learner
## (a tool, a basic need, a multiple-choice answer, or a function card).
##
## `icon` stays null until real art exists. OptionCard draws a labelled
## colour block in its place, so the whole game is playable with zero assets.

@export var id: StringName = &""
@export var label: String = ""

## Drop the final art here later. Nothing else has to change.
@export var icon: Texture2D

## Used only while `icon` is null.
@export var placeholder_color: Color = Color(0.45, 0.62, 0.35)

## Shown when this item is chosen for a challenge where it is not the answer.
## Write one per item, not one per (item x challenge) pair.
@export_multiline var wrong_hint: String = "Oops, let's try again!"

## Optional voice-over line key for this item's label (see localisation notes).
@export var vo_key: StringName = &""
