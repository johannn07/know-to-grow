@tool
extends EditorScript

## Run once: open this file in the Godot script editor and press
## File > Run (Ctrl+Shift+X). It writes res://content/level_1..4.tres
## containing every prompt, option, hint and fun fact from the design doc.
##
## After that, edit the .tres files in the Inspector, not this script.
## Re-running overwrites them.

const OUT_DIR := "res://content"

# Placeholder colours, grouped by kind, so a grey-box build is still readable.
const C_TOOL := Color(0.62, 0.45, 0.30)
const C_NEED := Color(0.98, 0.78, 0.25)
const C_DISTRACTOR := Color(0.55, 0.58, 0.62)
const C_PART := Color(0.35, 0.62, 0.35)
const C_FUNCTION := Color(0.45, 0.55, 0.80)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	_save(_level_1(), "level_1_planting.tres")
	_save(_level_2(), "level_2_monitoring.tres")
	_save(_level_3(), "level_3_identifying.tres")
	_save(_level_4(), "level_4_functions.tres")
	print("Know to Grow: content written to %s" % OUT_DIR)


# --- level 1: planting -------------------------------------------------------

func _level_1() -> LevelData:
	var shovel := _opt("shovel", "Shovel", C_TOOL, "The shovel digs in the soil. Is that what we need right now?")
	var can := _opt("watering_can", "Watering Can", C_TOOL, "Water is important, but not for this step yet!")
	var flower := _opt("flower", "Flower", C_DISTRACTOR, "A flower is lovely, but it can't do this job.")
	var seed_packet := _opt("seed_packet", "Seed Packet", C_NEED, "")
	var rock := _opt("rock", "Rock", C_DISTRACTOR, "A rock will never grow into a plant.")
	var leaf := _opt("leaf", "Leaf", C_DISTRACTOR, "A leaf comes from a plant, but it can't start a new one.")
	var sun := _opt("sun", "Sun", C_NEED, "The sun is up in the sky, not down in the soil.")
	var gloves := _opt("gloves", "Gloves", C_DISTRACTOR, "Gloves keep our hands clean, but the soil needs something else.")
	var cloud := _opt("cloud", "Cloud", C_DISTRACTOR, "A cloud hides the light. Plants want more light!")
	var moon := _opt("moon", "Moon", C_DISTRACTOR, "The moon glows at night, but plants need a stronger light.")

	var level := LevelData.new()
	level.id = &"level_1"
	level.title = "Level 1: Planting"
	level.instruction = "Let's plant a seed! Tap the correct tool or object, then drag it where it belongs."
	level.shuffle_challenges = false  # planting is a real-world sequence
	level.completion_message = "You planted a seed all by yourself!"
	level.final_fun_fact = "A seed needs soil, water and sunlight to wake up and grow."
	level.challenges = [
		_challenge("l1_dig", "First, we need a little hole in the soil for our seed. Which tool do we use?",
			[shovel, can, flower], "shovel",
			"Digging a small hole gives the seed a cozy place to rest and grow!",
			"soil", "empty_bed", "hole_dug"),
		_challenge("l1_seed", "Now, put one tiny seed into the hole. What goes inside?",
			[seed_packet, rock, leaf], "seed_packet",
			"Inside every seed is a tiny baby plant just waiting to wake up!",
			"soil", "hole_dug", "seed_covered"),
		_challenge("l1_water", "The seed is thirsty! What do we pour gently over the soil?",
			[can, sun, gloves], "watering_can",
			"Water helps the seed wake up and begin to grow!",
			"soil", "seed_covered", "soil_watered"),
		_challenge("l1_sun", "Plants need light to help make food. What shines down to help the plant grow?",
			[sun, cloud, moon], "sun",
			"Plants use sunlight, water and air to help make their own food!",
			"sky", "soil_watered", "sprout"),
	]
	return level


# --- level 2: monitoring -----------------------------------------------------

func _level_2() -> LevelData:
	# The same six items stay on screen for all five situations, so each item
	# carries ONE hint that reads correctly in any of them.
	var shovel := _opt("shovel", "Shovel", C_TOOL, "A shovel loosens hard soil. Look again at what this plant needs.")
	var shears := _opt("pruning_shears", "Pruning Shears", C_TOOL, "Shears trim away dead parts. Is anything dead or brown here?")
	var can := _opt("watering_can", "Watering Can", C_TOOL, "The watering can is for thirsty soil. Check the problem again.")
	var sunlight := _opt("sunlight", "Sunlight", C_NEED, "Not quite! This plant needs help with something other than light right now.")
	var water := _opt("water", "Water", C_NEED, "Water is for a thirsty plant. Look closely at what is wrong.")
	var fertilizer := _opt("fertilizer", "Fertilizer", C_NEED, "Fertilizer adds nutrients. Is that what this plant is asking for?")
	var pool: Array[OptionData] = [shovel, shears, can, sunlight, water, fertilizer]

	var level := LevelData.new()
	level.id = &"level_2"
	level.title = "Level 2: Monitoring"
	level.instruction = "Help the plant! Drag the correct tool or basic need to fix its situation."
	level.shuffle_challenges = true
	level.completion_message = "You took great care of the plant!"
	level.final_fun_fact = "Plants tell us what they need — we just have to look closely."
	level.challenges = [
		_challenge("l2_hard_soil", "The soil is hard and dry.", pool, "shovel",
			"A shovel helps loosen hard soil so the plant's roots can grow.",
			"plant", "hard_dry_soil"),
		_challenge("l2_dead_leaves", "The plant has dead, brown leaves.", pool, "pruning_shears",
			"Pruning shears remove dead parts of a plant and keep it healthy.",
			"plant", "brown_leaves"),
		_challenge("l2_thirsty", "The soil is dry and the plant needs a drink.", pool, "watering_can",
			"Water gives the plant what it needs to stay hydrated and grow.",
			"plant", "dry_soil"),
		_challenge("l2_light", "The plant looks sad and needs light.", pool, "sunlight",
			"Sunlight provides the energy plants need to help make food.",
			"plant", "needs_light"),
		_challenge("l2_nutrients", "The plant needs extra nutrients to grow.", pool, "fertilizer",
			"Fertilizer provides nutrients that help plants grow.",
			"plant", "needs_nutrients"),
	]
	# "Watering Can" and "Water" are both fair answers to the thirsty plant.
	level.challenges[2].alternate_correct_ids = [&"water"]
	return level


# --- level 3: identifying ----------------------------------------------------

func _level_3() -> LevelData:
	var roots := _opt("roots", "Roots", C_PART, "Roots are the part that lives underground.")
	var stem := _opt("stem", "Stem", C_PART, "The stem is the tall part that holds everything up.")
	var leaves := _opt("leaves", "Leaves", C_PART, "Leaves are the flat green parts.")
	var flower := _opt("flower", "Flower", C_PART, "The flower is the bright, colourful part.")
	var fruit := _opt("fruit", "Fruit", C_PART, "The fruit grows after the flower.")

	var level := LevelData.new()
	level.id = &"level_3"
	level.title = "Level 3: Identifying"
	level.instruction = "Look closely at the plant. Can you identify the plant part?"
	level.shuffle_challenges = false
	level.shuffle_options = true  # the scripted answers sit at B, A, C, A, B
	level.completion_message = "You know all the parts of a plant!"
	level.final_fun_fact = "Every plant part has its own name and its own job."
	level.challenges = [
		_tap("l3_leaves", "I am green and flat. What am I?", [roots, leaves, flower], "leaves",
			"Leaves capture sunlight and help the plant make food!", "highlight_leaves"),
		_tap("l3_stem", "I stand tall like a trunk or a straw. What am I?", [stem, fruit, roots], "stem",
			"The stem holds the plant upright and carries water to other parts!", "highlight_stem"),
		_tap("l3_roots", "I live underground in the soil. What am I?", [flower, stem, roots], "roots",
			"Roots hold the plant firmly in the soil and absorb water and nutrients!", "highlight_roots"),
		_tap("l3_flower", "I am bright and colourful. What am I?", [flower, leaves, stem], "flower",
			"Flowers help plants reproduce by helping them make seeds!", "highlight_flower"),
		_tap("l3_fruit", "I grow after the flower. What am I?", [roots, fruit, leaves], "fruit",
			"Fruits protect the seeds and help them develop into new plants!", "highlight_fruit"),
	]
	return level


# --- level 4: functions ------------------------------------------------------

func _level_4() -> LevelData:
	var make_food := _opt("fn_make_food", "Help make food using sunlight.", C_FUNCTION,
		"Only one part catches the sunlight. Try another part.")
	var absorb_hold := _opt("fn_absorb_hold", "Absorb water and nutrients and hold the plant in the soil.", C_FUNCTION,
		"That job happens underground. Try again!")
	var protect := _opt("fn_protect", "Protect the seeds.", C_FUNCTION,
		"Something does protect the seeds — but it isn't this part.")
	var support := _opt("fn_support", "Support the plant and carry water and nutrients.", C_FUNCTION,
		"That's the job of the part in the middle of the plant.")
	var reproduce := _opt("fn_reproduce", "Help the plant reproduce and make seeds.", C_FUNCTION,
		"The colourful part does that one. Try again!")
	var absorb_water := _opt("fn_absorb_water", "Absorb water from the soil.", C_FUNCTION,
		"That job happens down in the soil.")
	var hold := _opt("fn_hold", "Hold the plant firmly in the soil.", C_FUNCTION,
		"That job happens down in the soil.")
	var carry := _opt("fn_carry", "Carry water to the leaves.", C_FUNCTION,
		"That's the job of the part that holds the plant up.")

	var level := LevelData.new()
	level.id = &"level_4"
	level.title = "Level 4: Functions"
	level.instruction = "Now let's discover what each part does. Drag each function to the correct plant part."
	level.completion_message = "Fantastic! You know the parts of a plant and what each part does!"
	level.final_fun_fact = "Every plant part has an important job. Together, they help the plant live, grow and reproduce!"
	level.challenges = [
		_challenge("l4_roots", "What do the roots do?", [make_food, absorb_hold, protect], "fn_absorb_hold",
			"Roots hold the plant in the soil and absorb water and nutrients.",
			"roots", "highlight_roots"),
		_challenge("l4_stem", "What does the stem do?", [support, protect, make_food], "fn_support",
			"The stem supports the plant and helps move water and nutrients to different parts.",
			"stem", "highlight_stem"),
		_challenge("l4_leaves", "What do the leaves do?", [hold, make_food, protect], "fn_make_food",
			"Leaves use sunlight to help the plant make its own food.",
			"leaves", "highlight_leaves"),
		_challenge("l4_flower", "What does the flower do?", [absorb_water, reproduce, carry], "fn_reproduce",
			"Flowers help plants reproduce and produce seeds for new plants.",
			"flower", "highlight_flower"),
		_challenge("l4_fruit", "What does the fruit do?", [make_food, protect, absorb_water], "fn_protect",
			"Fruits protect the seeds inside and help them develop.",
			"fruit", "highlight_fruit"),
	]
	return level


# --- helpers -----------------------------------------------------------------

func _opt(id: String, label: String, color: Color, hint: String) -> OptionData:
	var option := OptionData.new()
	option.id = StringName(id)
	option.label = label
	option.placeholder_color = color
	option.vo_key = StringName("item_" + id)
	if hint != "":
		option.wrong_hint = hint
	return option


func _challenge(id: String, prompt: String, options: Array, correct: String, fact: String,
		zone: String, state: String, success: String = "") -> ChallengeData:
	var challenge := ChallengeData.new()
	challenge.id = StringName(id)
	challenge.prompt = prompt
	challenge.interaction = ChallengeData.Interaction.DRAG_TO_ZONE
	challenge.options.assign(options)
	challenge.correct_option_id = StringName(correct)
	challenge.fun_fact = fact
	challenge.zone_id = StringName(zone)
	challenge.scene_state = StringName(state)
	challenge.success_state = StringName(success)
	return challenge


func _tap(id: String, prompt: String, options: Array, correct: String, fact: String,
		state: String) -> ChallengeData:
	var challenge := _challenge(id, prompt, options, correct, fact, "main", state)
	challenge.interaction = ChallengeData.Interaction.TAP
	return challenge


func _save(level: LevelData, file_name: String) -> void:
	var path := "%s/%s" % [OUT_DIR, file_name]
	var err := ResourceSaver.save(level, path)
	if err != OK:
		push_error("Failed to save %s (%s)" % [path, err])
