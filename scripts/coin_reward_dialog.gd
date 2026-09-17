extends CanvasLayer
## Okno wyboru po zebraniu kolejnej setki pieniążków: +1 życie albo zachowanie pieniążków na sklep.
## Zatrzymuje grę do czasu wyboru.

## Krótka blokada przycisków, żeby wciśnięty akurat skok nie wybrał opcji przypadkiem.
const INPUT_DELAY := 0.4

@onready var title: Label = %Title
@onready var life_button: Button = %LifeButton
@onready var keep_button: Button = %KeepButton


func _ready() -> void:
	hide()
	GameState.coin_reward_available.connect(open)
	life_button.pressed.connect(_on_life_pressed)
	keep_button.pressed.connect(close)


func open() -> void:
	title.text = "Masz %d pieniążków!" % GameState.coins
	life_button.text = "+1 życie (-%d)" % GameState.LIFE_PRICE
	show()
	get_tree().paused = true

	life_button.disabled = true
	keep_button.disabled = true
	await get_tree().create_timer(INPUT_DELAY).timeout
	life_button.disabled = false
	keep_button.disabled = false
	life_button.grab_focus()


func close() -> void:
	hide()
	get_tree().paused = false


func _on_life_pressed() -> void:
	GameState.buy_life()
	close()
