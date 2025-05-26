extends Node2D

func toPolarAngle(cartesian):
	var angle=cartesian.angle_to(Vector2.RIGHT)
	if(angle<0):
		angle+=2*PI
	return angle
var movementSpeedThrough=4

func _ready():
	$MobSpawnTimeout.start()
	playerPosition=$Volvox.position
	$PlayTimer.start()
	$NameLabel.text=NameLabel
	$BestScoreLabel.text=str(BestScore)

@export var mob_scene: PackedScene
@export var mob_scale : float = .1
@export var paralaxBackground: ParallaxBackground
@export var speed=100
@export var mob_speed=3
@export var NameLabel=''
@export var BestScore=0
var playerPosition:Vector2;

signal gameover(score)
@export var ended=false

func move(amount: Vector2):
	for e in Enemies:
		e.MoveMe(-amount)
	paralaxBackground.offsetX=-amount.x
	paralaxBackground.offsetY=-amount.y
	#$Volvox.position=playerPosition+amount*movementSpeedThrough
	


func _process(delta):# delta - vremenski razmak izmedju frameova - krecu se istom brzinom nezavisno od fps
	if(!ended):      # fps - frekvencija, delta - talasna duzina
		refreshVector()
		
		#refreshing done, next is reacting, should be sepparate func
		var reflexMatrixN:DenseMatrix=DenseMatrix.from_packed_array(reflexMatrix,2,8)
		inputVectorN=VectorN.from_packed_array(inputVector)
		var reflexVector=reflexMatrixN.multiply_vector(inputVectorN).to_packed_array()
		var moveVector:Vector2 = Vector2(reflexVector[0],reflexVector[1]).normalized()*speed
		move(moveVector*delta)
		
	

var Enemies=[]
var inputVectorN:VectorN = VectorN.from_packed_array([0,0,0,0,0,0,0,0])
var inputVector=[0,0,0,0,0,0,0,0]
#@export reflexMatrix=[]

@export var reflexMatrix=[	randf()-.5,randf()-.5,
							randf()-.5,randf()-.5,
							randf()-.5,randf()-.5,
							randf()-.5,randf()-.5,
							randf()-.5,randf()-.5,
							randf()-.5,randf()-.5,
							randf()-.5,randf()-.5,
							randf()-.5,randf()-.5,
]

func refreshVector(): 
	inputVector=[0,0,0,0,0,0,0,0] # polarne koordinate, ali podeljeno u 8 "korpe" - bining
	for e in Enemies:
		var enemyOrientation: Vector2 = e.position-$Volvox.position
		var enemyMagnitude = enemyOrientation.length()
		var orientationAngle = toPolarAngle(enemyOrientation)
		
		var index = int((orientationAngle/(2*PI))*8)
		
		if(inputVector[index]==0 or inputVector[index]>enemyMagnitude):
				inputVector[int(index)]=enemyMagnitude




func _on_mob_spawn_timeout_timeout():
	var mob=mob_scene.instantiate()
	
	var mob_spawn_location=$MobPath/PathFollow2D
	mob_spawn_location.progress_ratio = randf()
	
	mob.position = mob_spawn_location.position
	mob.scale=Vector2(mob_scale,mob_scale)
	
	#var direction = mob_spawn_location.rotation + PI/2
	
	var aimat=($Volvox.position-mob.position).normalized()#.rotated(randf_range(-PI/16,PI/16))
	
	#direction += randf_range(-PI/4,PI/4)
	#mob.rotation = direction
	mob.rotation=aimat.angle()
	var velocity =  randf_range(1,2)*mob_speed
	mob.Direction = aimat#($Volvox.position-mob_spawn_location.position).normalized().rotated(randf_range(-PI/16,PI/16))
	mob.Speed = velocity
	
	$SpawnBorder.add_child(mob)
	Enemies.append(mob)
	
	



func _on_body_shape_exited(body_rid, body, body_shape_index, local_shape_index):
	
	for i in range(len(Enemies)):
		var e=Enemies[i]
		if(e==body):
			Enemies.remove_at(i)
			break
	body.queue_free()





func _on_area_exited(area):
	for i in range(len(Enemies)):
		var e=Enemies[i]
		if(e==area):
			Enemies.remove_at(i)
			break
	area.queue_free()


func _on_volvox_area_shape_entered(area_rid, area, area_shape_index, local_shape_index):
	score+=1-$PlayTimer.time_left
	$PlayTimer.stop()
	gameover.emit(score)
	gameOver()

func gameOver():
	$MobSpawnTimeout.stop()
	ended=true	
	move(Vector2(0,0))
	for e in Enemies:
		e.GameOver()
	$EndGameOverlay.visible=true
	

@export var score=0

func _on_play_timer_timeout():
	score+=1
	$ScoreLabel.text=str(score)
