extends Node
## Stan gry wspólny dla wszystkich poziomów (autoload "GameState"): życia, pieniążki i moc.

signal lives_changed(lives: int)
signal coins_changed(coins: int)
signal power_changed(power: Power)
## Pieniążki doszły do kolejnej setki – gracz wybiera: +1 życie albo zachować je na sklep.
signal coin_reward_available

## Moc kupiona w sklepiku. Działa do utraty życia; naraz tylko jedna.
enum Power { NONE, SEEDS, FREEZE }

const START_LIVES := 3
const COINS_PER_REWARD := 100
const LIFE_PRICE := 50

var lives := START_LIVES
var coins := 0
var power := Power.NONE
## Czy intro Miasta Jabłuszek było już pokazane (nie powtarzamy go np. po Game Over).
var intro_seen := false

var _next_reward_at := COINS_PER_REWARD


func add_coins(amount: int) -> void:
	coins += amount
	coins_changed.emit(coins)
	if coins >= _next_reward_at:
		_update_next_reward()
		coin_reward_available.emit()


## Wydaje pieniążki. Zwraca false, jeśli jest ich za mało.
func spend(amount: int) -> bool:
	if coins < amount:
		return false
	coins -= amount
	_update_next_reward()
	coins_changed.emit(coins)
	return true


## Kupuje życie za LIFE_PRICE pieniążków. Zwraca false, jeśli pieniążków jest za mało.
func buy_life() -> bool:
	if not spend(LIFE_PRICE):
		return false
	lives += 1
	lives_changed.emit(lives)
	return true


func set_power(new_power: Power) -> void:
	power = new_power
	power_changed.emit(power)


## Utrata życia zabiera też moc.
func lose_life() -> void:
	lives = maxi(lives - 1, 0)
	lives_changed.emit(lives)
	set_power(Power.NONE)


## Stan wczytany z zapisu gry.
func load_state(saved_lives: int, saved_coins: int, saved_power: int, saved_intro_seen: bool) -> void:
	lives = saved_lives
	coins = saved_coins
	intro_seen = saved_intro_seen
	_update_next_reward()
	lives_changed.emit(lives)
	coins_changed.emit(coins)
	set_power(saved_power as Power)


## Gra od samego początku, razem z intro.
func new_game() -> void:
	intro_seen = false
	reset()


## Nowa gra: pełne życia, zero pieniążków, bez mocy.
func reset() -> void:
	lives = START_LIVES
	coins = 0
	_update_next_reward()
	lives_changed.emit(lives)
	coins_changed.emit(coins)
	set_power(Power.NONE)


## Następna nagroda przy kolejnej pełnej setce powyżej obecnej liczby pieniążków.
func _update_next_reward() -> void:
	_next_reward_at = coins - coins % COINS_PER_REWARD + COINS_PER_REWARD
