extends Node2D


movement()

	#move_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	#if move_input != Vector2.ZERO:
		#facing = _direction_to_string(move_input)

	#if state == State.MOVE:
		#velocity = move_input * speed
		#move_and_slide()
	#else:
		#velocity = Vector2.ZERO

	#if Input.is_action_just_pressed("attack") and state == State.MOVE and _can_attack:
		#_attack()
		

	#_update_animation()
func movement():
	var x_mov= Input.get_action_strength("right")-Input.get_action_strength("left")
	var y_mov= Input.get_action_strength("down")-Input.get_action_strength("up")
	var mov= Vector2(x_mov,y_mov)
	velocity= mov.normalized()*move_speed
	
	if Input.is_action_just_pressed("attack"):
		if $AnimatedSprite2D.animation==("walk_right_sword"):
			$AnimatedSprite2D.play("sword_attack_right")
		elif $AnimatedSprite2D.animation==("walk_left_sword"):
			$AnimatedSprite2D.play("sword_attack_left")
		elif $AnimatedSprite2D.animation==("walk_down_sword"):
			$AnimatedSprite2D.play("sword_attack_down") 
		elif  $AnimatedSprite2D.animation==("walk_up_sword"):
			$AnimatedSprite2D.play("sword_attack_up")
	else:
		velocity = Vector2.ZERO

	if Input.is_action_just_pressed("attack") and state == State.MOVE and _can_attack:
		_attack()

	_update_animation()

		if x_mov > 0:
			$AnimatedSprite2D.play("walk_right_sword")
		elif x_mov < 0:
			$AnimatedSprite2D.play("walk_left_sword")
		elif y_mov > 0:
			$AnimatedSprite2D.play("walk_down_sword") 
		elif  y_mov<0:
			$AnimatedSprite2D.play("walk_up_sword")
	
	
	move_and_slide()
	
