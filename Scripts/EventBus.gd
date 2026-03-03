extends Node

enum state {
	NONE = 0,
	DRAW = 1 << 0,
	WALK = 1 << 1,
	RUN = 1 << 2,
	JUMP = 1 << 3,
	FALL = 1 << 4
}
var currentState: int = state.NONE

signal get_mesh(function: Callable)
