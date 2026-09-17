extends Node
## Stan gry wspólny dla wszystkich poziomów (autoload "GameState"): życia i pieniążki.

signal lives_changed(lives: int)
signal coins_changed(coins: int)
## Pieniążki doszły do kolejnej setki – gracz wybiera: +1 życie albo zachować je na sklep.
signal coin_reward_available

const START_LIVES := 3
const COINS_PER_REWARD := 100

var lives := START_LIVES
var coins := 0
## Czy intro Miasta Jabłuszek było już pokazane (nie powtarzamy go np. po Game Over).
var intro_seen := false

var _next_reward_at := COINS_PER_REWARD


func add_coins(amount: int) -> void:
	coins += amount
	coins_changed.emit(coins)
	if coins >= _next_reward_at:
		_update_next_reward()
		coin_reward_available.emit()


## Zamienia 100 pieniążków na życie. Zwraca false, jeśli pieniążków jest za mało.
func buy_life() -> bool:
	if coins < COINS_PER_REWARD:
		return false
	coins -= COINS_PER_REWARD
	lives += 1
	_update_next_reward()
	coins_changed.emit(coins)
	lives_changed.emit(lives)
	return true


func lose_life() -> void:
	lives = maxi(lives - 1, 0)
	lives_changed.emit(lives)


## Gra od samego początku, razem z intro.
func new_game() -> void:
	intro_seen = false
	reset()


## Nowa gra: pełne życia, zero pieniążków.
func reset() -> void:
	lives = START_LIVES
	coins = 0
	_update_next_reward()
	lives_changed.emit(lives)
	coins_changed.emit(coins)


## Następna nagroda przy kolejnej pełnej setce powyżej obecnej liczby pieniążków.
func _update_next_reward() -> void:
	_next_reward_at = coins - coins % COINS_PER_REWARD + COINS_PER_REWARD
