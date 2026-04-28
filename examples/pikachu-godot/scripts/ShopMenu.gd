extends CanvasLayer

const POTION_PRICE := 30
const BALL_PRICE := 50

@onready var money_lbl: Label = $Panel/V/Money
@onready var potion_btn: Button = $Panel/V/PotionButton
@onready var ball_btn: Button = $Panel/V/BallButton
@onready var close_btn: Button = $Panel/V/CloseButton
@onready var status_lbl: Label = $Panel/V/Status

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	potion_btn.pressed.connect(_buy_potion)
	ball_btn.pressed.connect(_buy_ball)
	close_btn.pressed.connect(_close)
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()

func _refresh() -> void:
	money_lbl.text = "$%d" % GameState.money
	potion_btn.text = "Buy Potion ($%d)  [have %d]" % [POTION_PRICE, int(GameState.inventory.get("potion", 0))]
	potion_btn.disabled = GameState.money < POTION_PRICE
	ball_btn.text = "Buy Pokeball ($%d)  [have %d]" % [BALL_PRICE, int(GameState.inventory.get("pokeball", 0))]
	ball_btn.disabled = GameState.money < BALL_PRICE

func _buy_potion() -> void:
	if GameState.spend_money(POTION_PRICE):
		GameState.grant_item("potion", 1)
		status_lbl.text = "Bought a Potion."
		_refresh()

func _buy_ball() -> void:
	if GameState.spend_money(BALL_PRICE):
		GameState.grant_item("pokeball", 1)
		status_lbl.text = "Bought a Pokeball."
		_refresh()

func _close() -> void:
	get_tree().paused = false
	GameState.save_game()
	queue_free()
