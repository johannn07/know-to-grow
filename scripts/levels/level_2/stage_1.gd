extends StageScreen

## Level 2 Situation 1 — Hard and Dry Soil.
##
## The pattern the other four situations copy. Unlike Level 1's stages it has no
## drawn prompt, header or fun fact strip: the prompt is live text in the shared
## %PromptBubble, the header is live text on the blank %HeaderSign, both read
## from content/level_2_monitoring.tres through [member StageScreen.level_content],
## and Level 2 has no fun fact by decision.
##
## The tray is the blank one, so [member StageScreen.blank_tray] is on and the
## three cards draw themselves over its empty slots. They must stay in the order
## the content lists them, left to right, since each is anchored over one slot.
##
## Level 2's Correct cards have no Continue drawn on them, so the Continue sits
## below the card, as on Level 1 Stage 4.
