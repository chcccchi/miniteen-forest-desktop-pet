extends Control

const SAVE_PATH := "user://harvest.json"
const KEYS_PER_COIN := 50
const KEY_EVENT_PORT := 48911
const ART_WIDTH := 2117.0
const ART_HEIGHT := 423.0
const RACCOON_MIN_X := 300.0
const CARD_FRAME_INSET := Vector2(10.0, 6.0)
const UNLOCK_COST := 50
const UNLOCK_SAVE_VERSION := 2
const CARD_SLOT_UNLOCKED: Texture2D = preload("res://assets/card-slot-frame.png")
const CARD_SLOT_LOCKED: Texture2D = preload("res://assets/card-slot-locked.png")
const PET_IDLE: Texture2D = preload("res://assets/pet-bunny-idle.png")
const PET_FRAME_1: Texture2D = preload("res://assets/pet-bunny-walk-1.png")
const PET_FRAME_2: Texture2D = preload("res://assets/pet-bunny-walk-2.png")
const RACCOON_IDLE: Texture2D = preload("res://assets/pet-idle.png")
const RACCOON_FRAME_1: Texture2D = preload("res://assets/pet-walk-1.png")
const RACCOON_FRAME_2: Texture2D = preload("res://assets/pet-walk-2.png")
const EXTRA_IDLE: Array[Texture2D] = [
	preload("res://assets/pet-bunny_calm-idle.png"), preload("res://assets/pet-bunny_gray-idle.png"),
	preload("res://assets/pet-cat_orange-idle.png"), preload("res://assets/pet-deer-idle.png"),
	preload("res://assets/pet-7-idle.png"), preload("res://assets/pet-8-idle.png"),
	preload("res://assets/pet-9-idle.png"), preload("res://assets/pet-10-idle.png"),
	preload("res://assets/pet-11-idle.png"), preload("res://assets/pet-12-idle.png"),
	preload("res://assets/pet-13-idle.png")
]
const EXTRA_FRAME_1: Array[Texture2D] = [
	preload("res://assets/pet-bunny_calm-walk-1.png"), preload("res://assets/pet-bunny_gray-walk-1.png"),
	preload("res://assets/pet-cat_orange-walk-1.png"), preload("res://assets/pet-deer-walk-1.png"),
	preload("res://assets/pet-7-walk-1.png"), preload("res://assets/pet-8-walk-1.png"),
	preload("res://assets/pet-9-walk-1.png"), preload("res://assets/pet-10-walk-1.png"),
	preload("res://assets/pet-11-walk-1.png"), preload("res://assets/pet-12-walk-1.png"),
	preload("res://assets/pet-13-walk-1.png")
]
const EXTRA_FRAME_2: Array[Texture2D] = [
	preload("res://assets/pet-bunny_calm-walk-2.png"), preload("res://assets/pet-bunny_gray-walk-2.png"),
	preload("res://assets/pet-cat_orange-walk-2.png"), preload("res://assets/pet-deer-walk-2.png"),
	preload("res://assets/pet-7-walk-2.png"), preload("res://assets/pet-8-walk-2.png"),
	preload("res://assets/pet-9-walk-2.png"), preload("res://assets/pet-10-walk-2.png"),
	preload("res://assets/pet-11-walk-2.png"), preload("res://assets/pet-12-walk-2.png"),
	preload("res://assets/pet-13-walk-2.png")
]

@onready var coin_button: Button = $CoinButton
@onready var house_button: Button = $HouseButton
@onready var bird_exit_button: Button = $BirdExitButton
@onready var flag_button: Button = $FlagButton
@onready var popup: Control = $Popup
@onready var popup_title: Label = $Popup/Title
@onready var popup_text: Label = $Popup/Body
@onready var released_status: Label = $Popup/ReleasedStatus
@onready var close_button: BaseButton = $Popup/Close
@onready var pet: TextureRect = $Pet
@onready var raccoon_pet: TextureRect = $PetRaccoon
@onready var raccoon_card: TextureButton = $Popup/RaccoonCard
@onready var bunny_card: TextureButton = $Popup/BunnyCard
@onready var extra_pets: Array[TextureRect] = [$PetCalm, $PetGray, $PetOrange, $PetDeer, $Pet7, $Pet8, $Pet9, $Pet10, $Pet11, $Pet12, $Pet13]
@onready var extra_cards: Array[TextureButton] = [$Popup/CalmCard, $Popup/GrayCard, $Popup/OrangeCard, $Popup/DeerCard, $Popup/Pet7Card, $Popup/Pet8Card, $Popup/Pet9Card, $Popup/Pet10Card, $Popup/Pet11Card, $Popup/Pet12Card, $Popup/Pet13Card]
@onready var card_slots: Array[TextureRect] = [$Popup/RaccoonSlot, $Popup/BunnySlot, $Popup/CalmSlot, $Popup/GraySlot, $Popup/OrangeSlot, $Popup/DeerSlot, $Popup/Pet7Slot, $Popup/Pet8Slot, $Popup/Pet9Slot, $Popup/Pet10Slot, $Popup/Pet11Slot, $Popup/Pet12Slot, $Popup/Pet13Slot]
@onready var scroll_thumb: ColorRect = $Popup/ScrollThumb
@onready var scroll_track: ColorRect = $Popup/ScrollTrack
@onready var scroll_left_icon: Label = $Popup/ScrollLeftIcon
@onready var scroll_right_icon: Label = $Popup/ScrollRightIcon

var today := ""
var today_key_presses := 0
var total_key_presses := 0
var coins := 0
var coins_spent := 0
# Every pet begins locked and is purchased from the warehouse.
var unlocked_pets: Array[bool] = [false, false, false, false, false, false, false, false, false, false, false, false, false]
var unlock_history: Array = []
var key_event_listener := PacketPeerUDP.new()
var listener_process_id := -1
var is_always_on_top := true
var pet_walking := false
var pet_direction := -1
var pet_walk_elapsed := 0.0
var pet_frame_elapsed := 0.0
var pet_second_frame := false
var raccoon_walking := false
var raccoon_direction := -1
var raccoon_walk_elapsed := 0.0
var raccoon_frame_elapsed := 0.0
var raccoon_second_frame := false
const PET_HOME_Y := 300.0
const MAX_VISIBLE_PETS := 5
# Debug workspace: allow every released pet to appear together.
# The downloadable build switches this one flag back to true.
const ENFORCE_VISIBLE_PET_LIMIT := false
var hotspot_sync_elapsed := 0.0
var release_order := 0
var extra_walking := [false, false, false, false, false, false, false, false, false, false, false]
var extra_directions := [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1]
var extra_walk_elapsed := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var extra_frame_elapsed := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var extra_second_frame := [false, false, false, false, false, false, false, false, false, false, false]
var card_scroll_index := 0
var card_page_positions: Array[Vector2] = []
var card_page_sizes: Array[Vector2] = []
const CARD_VISIBLE_COUNT := 4
var capacity_notice: Label

func _ready() -> void:
	# The first four slot nodes are editable layout templates. Cache exactly what
	# is in the scene so paging never overwrites the positions you tune in Godot.
	for index in CARD_VISIBLE_COUNT:
		card_page_positions.append(card_slots[index].position)
		card_page_sizes.append(card_slots[index].size)
	get_viewport().transparent_bg = true
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true)
	# Root-level coordinate hit tests are used because the art itself has transparent pixels.
	# The hidden Button nodes remain as editor-visible guides only.
	coin_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	house_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bird_exit_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flag_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	close_button.pressed.connect(_hide_popup)
	pet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raccoon_pet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raccoon_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bunny_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raccoon_card.hide()
	bunny_card.hide()
	for card_slot in card_slots:
		card_slot.hide()
	released_status.hide()
	for index in extra_pets.size():
		extra_pets[index].mouse_filter = Control.MOUSE_FILTER_IGNORE
		extra_pets[index].texture = EXTRA_IDLE[index]
		extra_pets[index].hide()
		extra_cards[index].mouse_filter = Control.MOUSE_FILTER_IGNORE
		extra_cards[index].hide()
	raccoon_pet.texture = RACCOON_IDLE
	raccoon_pet.hide()
	pet.texture = PET_IDLE
	pet.hide()
	_load_harvest()
	_apply_window_layer()
	popup.hide()
	_start_global_key_listener()
	call_deferred("_pin_to_screen_bottom")
	call_deferred("_sync_close_hotspot")

func _pin_to_screen_bottom() -> void:
	var screen := DisplayServer.window_get_current_screen()
	var usable_area := DisplayServer.screen_get_usable_rect(screen)
	var height := int(usable_area.size.x * ART_HEIGHT / ART_WIDTH)
	DisplayServer.window_set_size(Vector2i(usable_area.size.x, height))
	DisplayServer.window_set_position(Vector2i(usable_area.position.x, usable_area.end.y - height))

func _start_global_key_listener() -> void:
	if key_event_listener.bind(KEY_EVENT_PORT, "127.0.0.1") != OK:
		return
	var listener_path := ProjectSettings.globalize_path("res://native/KeyListenerWarehouseLayer.exe")
	if FileAccess.file_exists(listener_path):
		var window_handle := DisplayServer.window_get_native_handle(DisplayServer.WINDOW_HANDLE)
		var close_rect_path := ProjectSettings.globalize_path("user://close-hotspot.txt")
		var layer_mode_path := ProjectSettings.globalize_path("user://layer-mode.txt")
		listener_process_id = OS.create_process(listener_path, [str(KEY_EVENT_PORT), str(OS.get_process_id()), str(window_handle), close_rect_path, layer_mode_path])

func _process(_delta: float) -> void:
	while key_event_listener.get_available_packet_count() > 0:
		var packet := key_event_listener.get_packet()
		if packet.is_empty():
			continue
		match packet[0]:
			1, 75:
				_record_key_press()
			67:
				_open_coin_memory()
			72:
				_open_house()
			70:
				_toggle_window_layer()
			66:
				get_tree().quit()
			88:
				_hide_popup()
			81:
				_start_pet_walk(-1)
			82:
				_start_pet_walk(1)
			83:
				_toggle_raccoon()
			84:
				_toggle_bunny()
			85:
				if raccoon_pet.visible:
					_start_raccoon_walk(1 if randf() < 0.5 else -1)
			86:
				if pet.visible:
					_start_pet_walk(1 if randf() < 0.5 else -1)
			87:
				_start_extra_walk(0)
			89:
				_start_extra_walk(1)
			90:
				_start_extra_walk(2)
			91:
				_start_extra_walk(3)
			92:
				_toggle_extra_pet(0)
			93:
				_toggle_extra_pet(1)
			94:
				_toggle_extra_pet(2)
			95:
				_toggle_extra_pet(3)
			96:
				_scroll_cards(-1)
			97:
				_scroll_cards(1)
			98, 99, 100, 101, 102, 103, 104:
				_toggle_extra_pet(packet[0] - 94)
			105, 106, 107, 108, 109, 110, 111:
				_start_extra_walk(packet[0] - 101)
	_update_pet_walk(_delta)
	_update_raccoon_walk(_delta)
	_update_extra_pets(_delta)
	hotspot_sync_elapsed += _delta
	if hotspot_sync_elapsed >= 0.05:
		hotspot_sync_elapsed = 0.0
		_sync_close_hotspot()

func _visible_pet_count() -> int:
	var total: int = int(pet.visible) + int(raccoon_pet.visible)
	for extra_pet in extra_pets:
		total += int(extra_pet.visible)
	return total

func _show_capacity_notice() -> void:
	_refresh_warehouse_status()
	if is_instance_valid(capacity_notice):
		capacity_notice.queue_free()
	capacity_notice = Label.new()
	capacity_notice.text = "😖再多就挤不下啦！"
	# Parent it to the popup so moving/resizing the popup cannot make the notice drift.
	capacity_notice.position = Vector2(25.0, 152.0)
	capacity_notice.size = Vector2(250.0, 42.0)
	capacity_notice.z_index = 12
	capacity_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capacity_notice.add_theme_color_override("font_color", Color(0.95, 0.78, 0.20, 1.0))
	capacity_notice.add_theme_color_override("font_outline_color", Color(0.20, 0.10, 0.04, 1.0))
	capacity_notice.add_theme_constant_override("outline_size", 4)
	capacity_notice.add_theme_font_size_override("font_size", 21)
	popup.add_child(capacity_notice)
	var tween := create_tween()
	tween.tween_property(capacity_notice, "modulate:a", 0.0, 3.0)
	tween.tween_callback(capacity_notice.queue_free)

func _refresh_warehouse_status() -> void:
	if popup.visible and popup_title.text == "小屋":
		popup_text.text = "金币：%d 枚" % coins
		released_status.text = "已释放：%d/%d" % [_visible_pet_count(), MAX_VISIBLE_PETS] if ENFORCE_VISIBLE_PET_LIMIT else "已释放：%d/不限" % _visible_pet_count()
		released_status.show()

func _unlocked_pet_count() -> int:
	var total := 0
	for unlocked in unlocked_pets:
		total += int(unlocked)
	return total

func _try_unlock_pet(pet_index: int) -> bool:
	if unlocked_pets[pet_index]:
		return true
	if coins < UNLOCK_COST:
		return false
	coins -= UNLOCK_COST
	coins_spent += UNLOCK_COST
	_show_spend_feedback(UNLOCK_COST)
	unlocked_pets[pet_index] = true
	unlock_history.append({"pet": pet_index + 1, "cost": UNLOCK_COST, "date": Time.get_datetime_string_from_system()})
	_save_harvest()
	_refresh_warehouse_status()
	_layout_cards()
	return true

func _place_released_pet_on_top(released_pet: TextureRect) -> void:
	release_order += 1
	# Popup uses layer 10; the five pet layers stay below it.
	released_pet.z_index = min(2 + release_order, 9)

func _toggle_raccoon() -> void:
	if raccoon_pet.visible:
		raccoon_pet.hide()
		raccoon_walking = false
		raccoon_pet.texture = RACCOON_IDLE
		_refresh_warehouse_status()
		return
	if not _try_unlock_pet(0):
		return
	if ENFORCE_VISIBLE_PET_LIMIT and _visible_pet_count() >= MAX_VISIBLE_PETS:
		_show_capacity_notice()
		return
	raccoon_pet.show()
	_place_released_pet_on_top(raccoon_pet)
	_start_raccoon_walk(1 if randf() < 0.5 else -1)
	_refresh_warehouse_status()

func _toggle_bunny() -> void:
	if pet.visible:
		pet.hide()
		pet_walking = false
		pet.texture = PET_IDLE
		_refresh_warehouse_status()
		return
	if not _try_unlock_pet(1):
		return
	if ENFORCE_VISIBLE_PET_LIMIT and _visible_pet_count() >= MAX_VISIBLE_PETS:
		_show_capacity_notice()
		return
	pet.show()
	_place_released_pet_on_top(pet)
	_start_pet_walk(1 if randf() < 0.5 else -1)
	_refresh_warehouse_status()

func _toggle_extra_pet(index: int) -> void:
	var extra_pet: TextureRect = extra_pets[index]
	if extra_pet.visible:
		extra_pet.hide()
		extra_walking[index] = false
		extra_pet.texture = EXTRA_IDLE[index]
		_refresh_warehouse_status()
		return
	var extra_unlock_indices: Array[int] = [3, 5, 4, 2, 6, 7, 8, 9, 10, 11, 12]
	var pet_unlock_index: int = extra_unlock_indices[index]
	if not _try_unlock_pet(pet_unlock_index):
		return
	if ENFORCE_VISIBLE_PET_LIMIT and _visible_pet_count() >= MAX_VISIBLE_PETS:
		_show_capacity_notice()
		return
	extra_pet.show()
	_place_released_pet_on_top(extra_pet)
	_start_extra_walk(index)
	_refresh_warehouse_status()

func _start_extra_walk(index: int) -> void:
	var extra_pet: TextureRect = extra_pets[index]
	if not extra_pet.visible or extra_walking[index]:
		return
	var direction: int = 1 if randf() < 0.5 else -1
	if extra_pet.position.x <= 160.5 and direction < 0:
		direction = 1
	elif extra_pet.position.x >= 1499.5 and direction > 0:
		direction = -1
	extra_directions[index] = direction
	extra_pet.flip_h = direction > 0
	extra_walk_elapsed[index] = 0.0
	extra_frame_elapsed[index] = 0.0
	extra_second_frame[index] = false
	extra_pet.texture = EXTRA_FRAME_1[index]
	extra_walking[index] = true

func _update_extra_pets(delta: float) -> void:
	for index in extra_pets.size():
		if not extra_walking[index]:
			continue
		extra_walk_elapsed[index] += delta
		extra_frame_elapsed[index] += delta
		if extra_frame_elapsed[index] >= 0.125:
			extra_frame_elapsed[index] = 0.0
			extra_second_frame[index] = not extra_second_frame[index]
			extra_pets[index].texture = EXTRA_FRAME_2[index] if extra_second_frame[index] else EXTRA_FRAME_1[index]
		extra_pets[index].position.x = clampf(extra_pets[index].position.x + extra_directions[index] * 320.0 * delta, 160.0, 1500.0)
		if extra_walk_elapsed[index] >= 1.0:
			extra_walking[index] = false
			extra_pets[index].texture = EXTRA_IDLE[index]

func _all_cards() -> Array[TextureButton]:
	# Keep the inventory in the supplied asset numbering: 1 through 13.
	var cards: Array[TextureButton] = [raccoon_card, bunny_card, extra_cards[3], extra_cards[0], extra_cards[2], extra_cards[1]]
	for index in range(4, extra_cards.size()):
		cards.append(extra_cards[index])
	return cards

func _all_card_slots() -> Array[TextureRect]:
	var slots: Array[TextureRect] = [card_slots[0], card_slots[1], card_slots[5], card_slots[2], card_slots[4], card_slots[3]]
	for index in range(6, card_slots.size()):
		slots.append(card_slots[index])
	return slots

func _layout_cards() -> void:
	var cards: Array[TextureButton] = _all_cards()
	var slots: Array[TextureRect] = _all_card_slots()
	var max_scroll: int = _max_card_page_start(cards.size())
	card_scroll_index = clampi(card_scroll_index, 0, max_scroll)
	var cards_on_page: int = mini(CARD_VISIBLE_COUNT, cards.size() - card_scroll_index)
	# Center each page against the popup artwork. This keeps all four cards centered,
	# while a short final page (one to three cards) no longer hugs the left edge.
	var row_center_x: float = $Popup/PopupArt.position.x + $Popup/PopupArt.size.x * 0.5
	var gap: float = 0.0
	if CARD_VISIBLE_COUNT > 1:
		gap = card_page_positions[1].x - (card_page_positions[0].x + card_page_sizes[0].x)
	var cards_width: float = 0.0
	for page_index in cards_on_page:
		cards_width += card_page_sizes[page_index].x
	if cards_on_page > 1:
		cards_width += gap * float(cards_on_page - 1)
	var next_card_x: float = row_center_x - cards_width * 0.5
	for index in cards.size():
		var card: TextureButton = cards[index]
		var is_card_visible := popup.visible and popup_title.text == "小屋" and index >= card_scroll_index and index < card_scroll_index + CARD_VISIBLE_COUNT
		var is_unlocked: bool = unlocked_pets[index]
		var page_index: int = index - card_scroll_index
		var slot: TextureRect = slots[index]
		if page_index >= 0 and page_index < CARD_VISIBLE_COUNT:
			slot.position = Vector2(next_card_x, card_page_positions[page_index].y)
			slot.size = card_page_sizes[page_index]
			card.position = slot.position + CARD_FRAME_INSET
			card.size = slot.size - CARD_FRAME_INSET * 2.0
			next_card_x += slot.size.x + gap
		slot.texture = CARD_SLOT_UNLOCKED if is_unlocked else CARD_SLOT_LOCKED
		# Locked cards keep their pet artwork visible; the lock and price are an overlay.
		card.modulate.a = 1.0
		card.visible = is_card_visible
		slot.visible = is_card_visible
	var thumb_width: float = 560.0 * float(CARD_VISIBLE_COUNT) / float(cards.size())
	var thumb_left: float = -390.0 + (560.0 - thumb_width) * float(card_scroll_index) / float(maxi(1, max_scroll))
	scroll_thumb.position.x = thumb_left
	scroll_thumb.size.x = thumb_width

func _scroll_cards(direction: int) -> void:
	var max_scroll: int = _max_card_page_start(_all_cards().size())
	if max_scroll <= 0:
		return
	card_scroll_index += direction * CARD_VISIBLE_COUNT
	if card_scroll_index < 0:
		card_scroll_index = max_scroll
	elif card_scroll_index > max_scroll:
		card_scroll_index = 0
	_layout_cards()

func _max_card_page_start(card_count: int) -> int:
	var last_page: int = int(floor(float(card_count - 1) / float(CARD_VISIBLE_COUNT)))
	return maxi(0, last_page * CARD_VISIBLE_COUNT)

func _start_pet_walk(direction: int) -> void:
	if pet_walking:
		return
	if pet.position.x <= 160.5 and direction < 0:
		pet_direction = 1
	elif pet.position.x >= 1499.5 and direction > 0:
		pet_direction = -1
	else:
		pet_direction = direction
	pet.flip_h = pet_direction > 0
	pet_walk_elapsed = 0.0
	pet_frame_elapsed = 0.0
	pet_second_frame = false
	pet.texture = PET_FRAME_1
	pet.position.y = PET_HOME_Y
	pet_walking = true

func _update_pet_walk(delta: float) -> void:
	if not pet_walking:
		return
	pet_walk_elapsed += delta
	pet_frame_elapsed += delta
	if pet_frame_elapsed >= 0.125:
		pet_frame_elapsed = 0.0
		pet_second_frame = not pet_second_frame
		pet.texture = PET_FRAME_2 if pet_second_frame else PET_FRAME_1
	pet.position.x = clampf(pet.position.x + pet_direction * 320.0 * delta, 160.0, 1500.0)
	if pet_walk_elapsed >= 1.0:
		pet_walking = false
		pet.texture = PET_IDLE
		pet.position.y = PET_HOME_Y

func _start_raccoon_walk(direction: int) -> void:
	if raccoon_walking:
		return
	if raccoon_pet.position.x <= RACCOON_MIN_X + 0.5 and direction < 0:
		raccoon_direction = 1
	elif raccoon_pet.position.x >= 1499.5 and direction > 0:
		raccoon_direction = -1
	else:
		raccoon_direction = direction
	raccoon_pet.flip_h = raccoon_direction > 0
	raccoon_walk_elapsed = 0.0
	raccoon_frame_elapsed = 0.0
	raccoon_second_frame = false
	raccoon_pet.texture = RACCOON_FRAME_1
	raccoon_walking = true

func _update_raccoon_walk(delta: float) -> void:
	if not raccoon_walking:
		return
	raccoon_walk_elapsed += delta
	raccoon_frame_elapsed += delta
	if raccoon_frame_elapsed >= 0.125:
		raccoon_frame_elapsed = 0.0
		raccoon_second_frame = not raccoon_second_frame
		raccoon_pet.texture = RACCOON_FRAME_2 if raccoon_second_frame else RACCOON_FRAME_1
	raccoon_pet.position.x = clampf(raccoon_pet.position.x + raccoon_direction * 320.0 * delta, RACCOON_MIN_X, 1500.0)
	if raccoon_walk_elapsed >= 1.0:
		raccoon_walking = false
		raccoon_pet.texture = RACCOON_IDLE

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# The two editor boxes are the single source of truth for click areas.
		# Move or resize CoinButton / HouseButton in the scene and the click area follows.
		if bird_exit_button.get_rect().has_point(event.position):
			get_tree().quit()
			accept_event()
		elif coin_button.get_rect().has_point(event.position):
			_open_coin_memory()
			accept_event()
		elif house_button.get_rect().has_point(event.position):
			_open_house()
			accept_event()
		elif flag_button.get_rect().has_point(event.position):
			_toggle_window_layer()
			accept_event()

func _toggle_window_layer() -> void:
	is_always_on_top = not is_always_on_top
	_apply_window_layer()
	_save_harvest()

func _apply_window_layer() -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, is_always_on_top)
	var layer_file := FileAccess.open("user://layer-mode.txt", FileAccess.WRITE)
	if layer_file:
		layer_file.store_string("top" if is_always_on_top else "bottom")

func _unhandled_key_input(event: InputEvent) -> void:
	if listener_process_id == -1 and event is InputEventKey and event.pressed and not event.echo:
		_record_key_press()

func _record_key_press() -> void:
	today_key_presses += 1
	total_key_presses += 1
	if total_key_presses % KEYS_PER_COIN == 0:
		coins += 1
	_save_harvest()
	_show_coin_feedback()
	if popup.visible and popup_title.text == "统计":
		_open_coin_memory()

func _show_coin_feedback() -> void:
	var feedback := Label.new()
	feedback.text = "+1"
	feedback.position = coin_button.position + Vector2(80, -24)
	feedback.size = Vector2(80, 42)
	feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback.z_index = 10
	feedback.add_theme_color_override("font_color", Color(1.0, 0.82, 0.08, 1.0))
	feedback.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.02, 1.0))
	feedback.add_theme_constant_override("outline_size", 5)
	feedback.add_theme_font_size_override("font_size", 40)
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(feedback)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(feedback, "position:y", feedback.position.y - 58.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(feedback, "modulate:a", 0.0, 0.8)
	tween.set_parallel(false)
	tween.tween_callback(feedback.queue_free)

func _show_spend_feedback(cost: int) -> void:
	var feedback := Label.new()
	feedback.text = "-$%d" % cost
	feedback.position = coin_button.position + Vector2(70.0, -20.0)
	feedback.size = Vector2(120.0, 42.0)
	feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback.z_index = 10
	feedback.add_theme_color_override("font_color", Color(0.95, 0.30, 0.16, 1.0))
	feedback.add_theme_color_override("font_outline_color", Color(0.10, 0.03, 0.02, 1.0))
	feedback.add_theme_constant_override("outline_size", 5)
	feedback.add_theme_font_size_override("font_size", 34)
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(feedback)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(feedback, "position:y", feedback.position.y - 54.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(feedback, "modulate:a", 0.0, 0.9)
	tween.set_parallel(false)
	tween.tween_callback(feedback.queue_free)

func _open_coin_memory() -> void:
	raccoon_card.hide()
	bunny_card.hide()
	for card_slot in card_slots:
		card_slot.hide()
	for extra_card in extra_cards:
		extra_card.hide()
	scroll_track.hide()
	scroll_thumb.hide()
	scroll_left_icon.hide()
	scroll_right_icon.hide()
	released_status.hide()
	popup_title.text = "统计（50 次敲击 = 1 金币）"
	popup_text.text = "金币：%d 枚\n今日打字：%d 次\n累计打字：%d 次" % [coins, today_key_presses, total_key_presses]
	popup.show()
	call_deferred("_sync_close_hotspot")

func _open_house() -> void:
	popup_title.text = "小屋"
	popup.show()
	_refresh_warehouse_status()
	scroll_track.show()
	scroll_thumb.show()
	scroll_left_icon.show()
	scroll_right_icon.show()
	_layout_cards()
	call_deferred("_sync_close_hotspot")

func _hide_popup() -> void:
	popup.hide()
	released_status.hide()
	raccoon_card.hide()
	bunny_card.hide()
	for card_slot in card_slots:
		card_slot.hide()
	for extra_card in extra_cards:
		extra_card.hide()
	_sync_close_hotspot()

func _sync_close_hotspot() -> void:
	var rect := close_button.get_global_rect()
	var message := "C|%.2f|%.2f|%.2f|%.2f|%d" % [rect.position.x, rect.position.y, rect.size.x, rect.size.y, 1 if popup.visible else 0]
	var in_warehouse := popup.visible and popup_title.text == "小屋"
	var raccoon_rect := raccoon_card.get_global_rect()
	var bunny_rect := bunny_card.get_global_rect()
	message += "\nR|%.2f|%.2f|%.2f|%.2f|%d" % [raccoon_rect.position.x, raccoon_rect.position.y, raccoon_rect.size.x, raccoon_rect.size.y, 1 if in_warehouse and raccoon_card.visible else 0]
	message += "\nB|%.2f|%.2f|%.2f|%.2f|%d" % [bunny_rect.position.x, bunny_rect.position.y, bunny_rect.size.x, bunny_rect.size.y, 1 if in_warehouse and bunny_card.visible else 0]
	var bunny_pet_rect := pet.get_global_rect()
	var raccoon_pet_rect := raccoon_pet.get_global_rect()
	message += "\nW|%.2f|%.2f|%.2f|%.2f|%d" % [bunny_pet_rect.position.x, bunny_pet_rect.position.y, bunny_pet_rect.size.x, bunny_pet_rect.size.y, 1 if pet.visible else 0]
	message += "\nX|%.2f|%.2f|%.2f|%.2f|%d" % [raccoon_pet_rect.position.x, raccoon_pet_rect.position.y, raccoon_pet_rect.size.x, raccoon_pet_rect.size.y, 1 if raccoon_pet.visible else 0]
	var extra_card_types: Array[String] = ["D", "E", "F", "G", "H", "I", "J", "K", "M", "O", "P"]
	var extra_pet_types: Array[String] = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "Q"]
	for index in extra_pets.size():
		var extra_card_rect: Rect2 = extra_cards[index].get_global_rect()
		var extra_pet_rect: Rect2 = extra_pets[index].get_global_rect()
		message += "\n%s|%.2f|%.2f|%.2f|%.2f|%d" % [extra_card_types[index], extra_card_rect.position.x, extra_card_rect.position.y, extra_card_rect.size.x, extra_card_rect.size.y, 1 if extra_cards[index].visible else 0]
		message += "\n%s|%.2f|%.2f|%.2f|%.2f|%d" % [extra_pet_types[index], extra_pet_rect.position.x, extra_pet_rect.position.y, extra_pet_rect.size.x, extra_pet_rect.size.y, 1 if extra_pets[index].visible else 0]
	# These hit areas must follow the visible arrows: the popup itself can be moved
	# freely in the editor, so fixed popup-relative coordinates drift out of sync.
	# Keep the generous hit area attached to the arrow art itself, not a stale
	# hard-coded coordinate. This also leaves the card slots fully clickable.
	var left_scroll_rect: Rect2 = scroll_left_icon.get_global_rect().grow(22.0)
	var right_scroll_rect: Rect2 = scroll_right_icon.get_global_rect().grow(22.0)
	var max_card_scroll: int = _max_card_page_start(_all_cards().size())
	# Keep both arrows clickable at the boundaries: they wrap first ↔ last page.
	message += "\nL|%.2f|%.2f|%.2f|%.2f|%d" % [left_scroll_rect.position.x, left_scroll_rect.position.y, left_scroll_rect.size.x, left_scroll_rect.size.y, 1 if in_warehouse and max_card_scroll > 0 else 0]
	message += "\nN|%.2f|%.2f|%.2f|%.2f|%d" % [right_scroll_rect.position.x, right_scroll_rect.position.y, right_scroll_rect.size.x, right_scroll_rect.size.y, 1 if in_warehouse and max_card_scroll > 0 else 0]
	var sync_file := FileAccess.open("user://close-hotspot.txt", FileAccess.WRITE)
	if sync_file:
		sync_file.store_string(message)

func _load_harvest() -> void:
	today = Time.get_date_string_from_system()
	if not FileAccess.file_exists(SAVE_PATH):
		_save_harvest()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	if data is Dictionary:
		total_key_presses = int(data.get("total_key_presses", 0))
		coins = int(data.get("coins", 0))
		coins_spent = int(data.get("coins_spent", 0))
		is_always_on_top = bool(data.get("is_always_on_top", true))
		if int(data.get("unlock_save_version", 0)) >= UNLOCK_SAVE_VERSION:
			var saved_unlocked = data.get("unlocked_pets", [])
			if saved_unlocked is Array and saved_unlocked.size() == unlocked_pets.size():
				for index in unlocked_pets.size():
					unlocked_pets[index] = bool(saved_unlocked[index])
			var saved_history = data.get("unlock_history", [])
			if saved_history is Array:
				unlock_history = saved_history
		if data.get("date", "") == today:
			today_key_presses = int(data.get("today_key_presses", 0))
	_save_harvest()

func _save_harvest() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({
		"date": today,
		"today_key_presses": today_key_presses,
		"total_key_presses": total_key_presses,
		"coins": coins,
		"coins_spent": coins_spent,
		"is_always_on_top": is_always_on_top,
		"unlock_save_version": UNLOCK_SAVE_VERSION,
		"unlocked_pets": unlocked_pets,
		"unlock_history": unlock_history
	}))
