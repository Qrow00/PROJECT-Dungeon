# Dungeon Card — 3D Conversion Architecture

## Overview

Transform the existing 2D card-based dungeon crawler into a fully playable **3D dungeon crawler** in Godot 4, preserving all card/combat/data systems while adding a real 3D world layer with player movement, enemy AI, modular dungeons, and third-person camera.

## Architecture Layers

```
┌──────────────────────────────────────────┐
│               UI Layer                    │
│  HUD, Inventory, Card Combat, Menus      │
│  (Control nodes, overlays on viewport)    │
├──────────────────────────────────────────┤
│            Game Manager Layer            │
│  GameManager, CombatSystem, DeckManager   │
│  DungeonManager, LootSystem, PlayerData   │
│  (EXISTING — untouched)                   │
├──────────────────────────────────────────┤
│           3D World Layer                  │
│  PlayerController, EnemyAI, Dungeon3D     │
│  Navigation, Camera, Animations          │
│  (NEW — this document)                    │
└──────────────────────────────────────────┘
```

## Folder Structure

```
res://
├── scenes/
│   ├── player/
│   │   └── Player.tscn
│   ├── enemies/
│   │   ├── EnemyBase.tscn
│   │   ├── Goblin.tscn
│   │   ├── Skeleton.tscn
│   │   ├── Slime.tscn
│   │   ├── Cultist.tscn
│   │   ├── Demon.tscn
│   │   └── Dragon.tscn
│   ├── environments/
│   │   ├── DungeonRoom.tscn
│   │   ├── Corridor.tscn
│   │   ├── BossRoom.tscn
│   │   └── TreasureRoom.tscn
│   ├── dungeons/
│   │   └── DungeonWorld.tscn
│   ├── ui/
│   │   ├── HUD.tscn
│   │   ├── CardCombatUI.tscn
│   │   ├── InventoryUI.tscn
│   │   └── InteractionPrompt.tscn
│   ├── cards/
│   │   └── Card3D.tscn        (3D card object for world placement)
│   └── world/
│       ├── GameWorld.tscn      (new 3D root scene)
│       └── TitleScreen.tscn    (keep existing)
├── scripts/
│   ├── player/
│   │   ├── PlayerController.gd
│   │   ├── PlayerCamera.gd
│   │   ├── PlayerStats.gd      (wraps PlayerData)
│   │   └── PlayerInventory.gd  (wraps PlayerData)
│   ├── enemies/
│   │   ├── EnemyBase.gd
│   │   ├── StateMachine.gd
│   │   ├── states/
│   │   │   ├── IdleState.gd
│   │   │   ├── PatrolState.gd
│   │   │   ├── ChaseState.gd
│   │   │   ├── AttackState.gd
│   │   │   ├── ReturnState.gd
│   │   │   └── DeathState.gd
│   │   └── EnemyFactory.gd
│   ├── dungeon/
│   │   ├── DungeonWorld.gd
│   │   ├── RoomGenerator.gd
│   │   ├── Room.gd
│   │   └── EncounterTrigger.gd
│   ├── combat/
│   │   ├── CombatManager3D.gd  (bridge 3D ↔ existing CombatSystem)
│   │   └── CardCombatUI.gd
│   └── core/
│       ├── GameManager.gd      (enhanced — add 3D state)
│       ├── InteractionSystem.gd
│       └── GameState.gd
├── resources/
│   └── (existing + 3D themes)
├── materials/
│   ├── dungeon/
│   ├── characters/
│   └── effects/
├── audio/
│   ├── Music/
│   ├── SFX/
│   └── Narration/
├── models/
│   ├── characters/
│   ├── enemies/
│   ├── weapons/
│   ├── props/
│   └── dungeon/
├── animations/
│   ├── player/
│   └── enemies/
└── (existing files kept as-is)
```

---

## Phase 1 — Project Configuration

### project.godot changes

```gdscript
[application]
run/main_scene="res://scenes/world/GameWorld.tscn"

[rendering]
renderer/rendering_method="mobile"
renderer/rendering_method.mobile="opengl3_es"
```

### Physics Layers

| Layer | Name | Used by |
|-------|------|---------|
| 1 | World | Walls, floors, static geometry |
| 2 | Player | Player body |
| 3 | Enemy | Enemy bodies |
| 4 | PlayerHitbox | Player attack area |
| 5 | EnemyHitbox | Enemy attack area |
| 6 | Interactable | Chests, levers, triggers |
| 7 | Navigation | NavigationRegion3D |

Collision rules:
- Player(2) collides with World(1), Enemy(3), Interactable(6)
- Enemy(3) collides with World(1), Player(2)
- PlayerHitbox(4) detects Enemy(3)
- EnemyHitbox(5) detects Player(2)

---

## Phase 2 — Asset Pipeline

### Recommended Free Assets

**Player Character — Quaternius**
- `https://quaternius.com/downloads.html` → "Simple Robot" or "Adventurer" (CC0)
- GLB format, already rigged
- Alternative: Godot Asset Library "Low Poly Man" by SGS

**Enemies — Quaternius**
- Goblin, Skeleton, Slime, Demon from Quaternius Ultimate Monsters Pack (CC0)
- Dragon from Quaternius Dragon (CC0)
- Cultist from "Simple Cultist" pack

**Animations — Mixamo**
| Animation | Character Type | Notes |
|-----------|---------------|-------|
| Idle | Any humanoid | Loop |
| Walk | Any humanoid | Loop |
| Run | Any humanoid | Loop |
| Attack | Melee | 1-hit |
| Death | Any humanoid | Non-loop |
| Cast Spell | Mage/Cultist | For magic enemies |
| Block | Shield stance | For player blocking |

**Dungeon Assets — Quaternius / Kenney**
- Quaternius "Dungeon Pack" (CC0): walls, floors, pillars, doors, torches
- Kenney "Dungeon Kit" (CC0): chests, barrels, tables, braziers
- KayKit "Dungeon Pack" (CC0): additional props

**UI / Icons — Itch.io**
- Keep existing card art
- Add RPG icons from "RPG Icons Free" by 7Soul1 (CC-BY)

**Sound — Itch.io / FreeSound**
- Footsteps: `opengameart.org` stone footsteps
- UI clicks: Kenney UI Audio (CC0)
- Combat sounds: `freesound.org` sword swipes, impacts
- Ambient: dungeon ambiance loops

### Import Workflow

```
1. Download .glb/.fbx from source
2. If .fbx: Open in Blender, export as .glb (with embedded textures)
3. If already .glb: Direct import to Godot
4. For Mixamo: Download with "Skin" checked, "Without Morph Targets"
   → Import to Godot, add to AnimationTree
5. Configure Import:
   - Animation: Detect loops, set FPS to 30
   - Mesh: Compress vertex data, enable shadow casting
   - Material: Convert to Godot StandardMaterial3D
```

---

## Phase 3 — Player System

### Player.tscn Hierarchy

```
Player (CharacterBody3D)
├── CollisionShape3D (CapsuleShape3D, height=1.8, radius=0.4)
├── Model (Node3D)
│   └── (Imported GLB character model)
├── AnimationTree
│   ├── AnimationPlayer
│   └── StateMachine (Idle/Walk/Run/Attack/Death)
├── SpringArm3D
│   └── Camera3D (current = true, FOV = 75)
└── PlayerController (script)
```

### PlayerController.gd

```gdscript
class_name PlayerController
extends CharacterBody3D

# Movement
@export var walk_speed: float = 4.0
@export var run_speed: float = 7.0
@export var sprint_speed: float = 10.0
@export var acceleration: float = 10.0
@export var gravity: float = 9.8
@export var jump_velocity: float = 4.5

# References
@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var anim_player: AnimationPlayer = $AnimationPlayer

var current_speed: float = 0.0
var is_sprinting: bool = false
var is_attacking: bool = false

func _ready():
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * 0.003)
        spring_arm.rotation.x -= event.relative.y * 0.003
        spring_arm.rotation.x = clamp(spring_arm.rotation.x, -0.5, 1.2)

func _physics_process(delta):
    var move_input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction = (transform.basis * Vector3(move_input.x, 0, move_input.y)).normalized()

    if not is_on_floor():
        velocity.y -= gravity * delta

    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_velocity

    is_sprinting = Input.is_action_pressed("sprint")
    var target_speed = sprint_speed if is_sprinting else (run_speed if move_input.length() > 0 else 0.0)

    if direction:
        velocity.x = move_toward(velocity.x, direction.x * target_speed, acceleration * delta)
        velocity.z = move_toward(velocity.z, direction.z * target_speed, acceleration * delta)
    else:
        velocity.x = move_toward(velocity.x, 0, acceleration * delta)
        velocity.z = move_toward(velocity.z, 0, acceleration * delta)

    move_and_slide()
    update_animation(move_input.length(), target_speed)

func update_animation(movement_length: float, target: float):
    if is_attacking:
        anim_tree.set("parameters/state/transition_request", "attack")
        return
    if not is_on_floor():
        anim_tree.set("parameters/state/transition_request", "jump")
    elif movement_length > 0 and target > run_speed:
        anim_tree.set("parameters/state/transition_request", "sprint")
    elif movement_length > 0:
        anim_tree.set("parameters/state/transition_request", "walk")
    else:
        anim_tree.set("parameters/state/transition_request", "idle")

func attack():
    if is_attacking:
        return
    is_attacking = true
    anim_tree.set("parameters/state/transition_request", "attack")
    await anim_player.animation_finished
    is_attacking = false
```

### PlayerCamera.gd

```gdscript
class_name PlayerCamera
extends Node

@export var target: Node3D
@export var mouse_sensitivity: float = 0.003
@export var zoom_min: float = 2.0
@export var zoom_max: float = 10.0
@export var zoom_speed: float = 0.5

var current_zoom: float = 5.0
var first_person: bool = false

func _ready():
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
    if event is InputEventMouseMotion:
        target.rotate_y(-event.relative.x * mouse_sensitivity)
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            current_zoom = max(zoom_min, current_zoom - zoom_speed)
        if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            current_zoom = min(zoom_max, current_zoom + zoom_speed)

func toggle_first_person():
    first_person = not first_person
    # Toggle camera position between spring arm and head position
```

### PlayerStats.gd (bridge to PlayerData)

```gdscript
class_name PlayerStats
extends Node

@export var player_data: PlayerData

func get_hp() -> int: return player_data.hp
func get_max_hp() -> int: return player_data.max_hp
func take_damage(amount: int) -> int: return player_data.take_damage(amount)
func heal(amount: int) -> int: return player_data.heal(amount)
func is_alive() -> bool: return player_data.is_alive()
```

### Input Map

Create these actions in Project Settings → Input Map:
- `move_forward` (W, Up Arrow)
- `move_back` (S, Down Arrow)
- `move_left` (A, Left Arrow)
- `move_right` (D, Right Arrow)
- `sprint` (Shift)
- `jump` (Space)
- `interact` (E)
- `attack` (Left Mouse Button)
- `ability` (Right Mouse Button)
- `inventory` (I)
- `toggle_camera` (V)
- `pause` (Escape)
- `controller_move` (Left Stick)
- `controller_look` (Right Stick)
- `controller_interact` (A Button)

---

## Phase 4 — Enemy System

### State Machine Architecture

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│   IDLE    │────▶│  PATROL  │────▶│  CHASE   │
└────┬─────┘     └──────────┘     └────┬─────┘
     │                                  │
     │          ┌──────────┐            │
     └─────────▶│  RETURN  │◀───────────┘
                └──────────┘
     ┌──────────┐     ┌──────────┐
     │  ATTACK  │     │  DEATH   │
     └──────────┘     └──────────┘
```

### StateMachine.gd

```gdscript
class_name StateMachine
extends Node

signal state_changed(state: String)

@export var initial_state: String = "idle"
var current_state: State
var states: Dictionary = {}

func _ready():
    for child in get_children():
        if child is State:
            states[child.name.to_lower()] = child
    change_state(initial_state)

func change_state(state_name: String):
    if current_state:
        current_state.exit()
    current_state = states.get(state_name.to_lower())
    if current_state:
        current_state.enter()
        state_changed.emit(state_name)

func _physics_process(delta):
    if current_state:
        current_state.update(delta)
```

### State.gd

```gdscript
class_name State
extends Node

var enemy: EnemyBase
var state_machine: StateMachine

func _ready():
    await owner.ready
    enemy = owner as EnemyBase
    state_machine = enemy.get_node("StateMachine")

func enter():
    pass
func exit():
    pass
func update(delta: float):
    pass
```

### IdleState.gd

```gdscript
extends State

var idle_timer: float = 0.0

func enter():
    idle_timer = randf_range(2.0, 5.0)
    enemy.anim_tree.set("parameters/state/transition_request", "idle")

func update(delta):
    idle_timer -= delta
    if idle_timer <= 0:
        state_machine.change_state("patrol")
    if enemy.detection_zone.is_target_in_range():
        state_machine.change_state("chase")
```

### PatrolState.gd

```gdscript
extends State

var patrol_point: Vector3
var patrol_index: int = 0

func enter():
    enemy.anim_tree.set("parameters/state/transition_request", "walk")
    if enemy.patrol_points.size() > 0:
        patrol_point = enemy.patrol_points[patrol_index]
        enemy.nav_agent.target_position = patrol_point

func update(delta):
    if enemy.detection_zone.is_target_in_range():
        state_machine.change_state("chase")
        return
    if enemy.nav_agent.is_navigation_finished():
        patrol_index = (patrol_index + 1) % enemy.patrol_points.size()
        patrol_point = enemy.patrol_points[patrol_index]
        enemy.nav_agent.target_position = patrol_point
```

### ChaseState.gd

```gdscript
extends State

func enter():
    enemy.anim_tree.set("parameters/state/transition_request", "run")
    enemy.aggro = true

func update(delta):
    var target = enemy.detection_zone.target
    if not target or not is_instance_valid(target):
        state_machine.change_state("return")
        return
    enemy.nav_agent.target_position = target.global_position
    var dist = enemy.global_position.distance_to(target.global_position)
    if dist < enemy.attack_range:
        state_machine.change_state("attack")
```

### AttackState.gd

```gdscript
extends State

var attack_cooldown: float = 0.0

func enter():
    enemy.anim_tree.set("parameters/state/transition_request", "attack")
    attack_cooldown = enemy.attack_speed

func update(delta):
    attack_cooldown -= delta
    if attack_cooldown <= 0:
        # Deal damage to player via CombatManager3D
        enemy.deal_damage.emit(enemy.damage)
        # Check if player still in range
        var target = enemy.detection_zone.target
        if target and enemy.global_position.distance_to(target.global_position) < enemy.attack_range:
            state_machine.change_state("chase")
        else:
            state_machine.change_state("return")
```

### ReturnState.gd

```gdscript
extends State

func enter():
    enemy.anim_tree.set("parameters/state/transition_request", "walk")
    enemy.nav_agent.target_position = enemy.spawn_position
    enemy.aggro = false

func update(delta):
    if enemy.detection_zone.is_target_in_range():
        state_machine.change_state("chase")
        return
    if enemy.nav_agent.is_navigation_finished():
        state_machine.change_state("idle")
```

### DeathState.gd

```gdscript
extends State

func enter():
    enemy.anim_tree.set("parameters/state/transition_request", "death")
    enemy.set_collision_layer_value(3, false)
    enemy.set_collision_mask_value(1, false)
    enemy.destroy_timer.start()

func update(delta):
    pass # wait for animation + timer
```

### EnemyBase.tscn

```
Enemy (CharacterBody3D)
├── CollisionShape3D (CapsuleShape3D)
├── Model (Node3D) ── (GLB model)
├── NavigationAgent3D
├── DetectionZone (Area3D)
│   └── CollisionShape3D (SphereShape3D, radius=10.0)
├── AttackZone (Area3D)
│   └── CollisionShape3D (SphereShape3D, radius=2.0)
├── AnimationTree
│   └── AnimationPlayer
├── StateMachine (Node)
│   ├── IdleState
│   ├── PatrolState
│   ├── ChaseState
│   ├── AttackState
│   ├── ReturnState
│   └── DeathState
└── EnemyBase (script)
```

### EnemyBase.gd

```gdscript
class_name EnemyBase
extends CharacterBody3D

signal deal_damage(amount: int)
signal died(enemy: EnemyBase)

@export var enemy_data: MonsterData
@export var walk_speed: float = 2.0
@export var run_speed: float = 4.0
@export var attack_range: float = 2.0
@export var attack_speed: float = 1.5
@export var damage: int = 5
@export var patrol_points: Array[Vector3] = []

var nav_agent: NavigationAgent3D
var anim_tree: AnimationTree
var anim_player: AnimationPlayer
var spawn_position: Vector3
var aggro: bool = false
var hp: int
var max_hp: int

@onready var detection_zone: Area3D = $DetectionZone
@onready var destroy_timer: Timer = $DestroyTimer

func _ready():
    spawn_position = global_position
    nav_agent = $NavigationAgent3D
    anim_tree = $AnimationTree
    anim_player = $AnimationPlayer
    if enemy_data:
        hp = enemy_data.hp
        max_hp = enemy_data.max_hp
        damage = enemy_data.roll_damage()

func _physics_process(delta):
    var next_pos = nav_agent.get_next_path_position()
    var dir = (next_pos - global_position).normalized()
    var speed = run_speed if aggro else walk_speed
    velocity = dir * speed
    velocity.y -= 9.8 * delta
    if dir.length() > 0:
        look_at(global_position + dir, Vector3.UP, true)
    move_and_slide()

func take_damage(amount: int) -> int:
    hp -= amount
    if hp <= 0:
        die()
    return amount

func die():
    $StateMachine.change_state("death")
    died.emit(self)
    await $DestroyTimer.timeout
    queue_free()
```

### EnemyFactory.gd

```gdscript
class_name EnemyFactory
extends Node

const ENEMY_SCENES = {
    "goblin": preload("res://scenes/enemies/Goblin.tscn"),
    "skeleton": preload("res://scenes/enemies/Skeleton.tscn"),
    "slime": preload("res://scenes/enemies/Slime.tscn"),
    "cultist": preload("res://scenes/enemies/Cultist.tscn"),
    "demon": preload("res://scenes/enemies/Demon.tscn"),
    "dragon": preload("res://scenes/enemies/Dragon.tscn"),
}

func spawn_enemy(enemy_data: MonsterData, position: Vector3, parent: Node) -> EnemyBase:
    var scene = ENEMY_SCENES.get(enemy_data.monster_type, ENEMY_SCENES["goblin"])
    var instance = scene.instantiate()
    instance.enemy_data = enemy_data
    instance.position = position
    parent.add_child(instance)
    return instance
```

---

## Phase 5 — Dungeon System

### Modular Room System

Each room is a `.tscn` with:
- StaticBody3D walls/floor/ceiling
- NavigationRegion3D on floor
- SpawnPoint3D markers for enemies
- SpawnPoint3D markers for loot
- EncounterTrigger Area3D

### Room Types (mapped to existing DungeonManager.RoomType)

| RoomType | 3D Scene | Features |
|----------|----------|----------|
| MONSTER | MonsterRoom.tscn | Enemy spawns, encounter trigger |
| TREASURE | TreasureRoom.tscn | Chests, loot pickups |
| REST | RestRoom.tscn | Campfire, heal trigger |
| EVENT | EventRoom.tscn | Rune pedestal, interaction |
| SHOP | ShopRoom.tscn | Merchant NPC |
| BOSS | BossRoom.tscn | Large arena, boss spawn |
| SECRET | SecretRoom.tscn | Hidden door, rare loot |

### DungeonWorld.gd

```gdscript
class_name DungeonWorld
extends Node3D

@export var room_scenes: Dictionary = {}
@export var corridor_scene: PackedScene

var current_room: Room
var rooms: Array[Room] = []
var nav_region: NavigationRegion3D

func generate_from_dungeon_manager():
    var dm = GameManager.dungeon
    var layout = dm.floor_rooms
    for i in range(layout.size()):
        var room_type = dm.get_room_label(layout[i])
        var room = create_room(layout[i], i)
        rooms.append(room)
        add_child(room)
    
    connect_rooms_with_corridors()
    bake_navigation()

func create_room(type: int, index: int) -> Room:
    var scene = room_scenes.get(type, room_scenes[0])
    var room = scene.instantiate()
    room.room_type = type
    room.room_index = index
    room.position = Vector3(index * 20, 0, 0)  # Linear layout
    room.encounter_trigger.connect(_on_encounter_triggered)
    return room

func _on_encounter_triggered(room: Room):
    var monsters = GameManager.generate_encounter(
        GameManager.dungeon.floor_number,
        GameManager.dungeon.get_monster_encounter_size(GameManager.dungeon.floor_number)
    )
    for monster_data in monsters:
        var spawn = room.get_random_enemy_spawn()
        EnemyFactory.spawn_enemy(monster_data, spawn, room)
```

### Room.gd

```gdscript
class_name Room
extends Node3D

signal encounter_triggered(room: Room)

@export var room_type: int
@export var room_index: int
@export var enemy_spawn_points: Array[Node3D] = []
@export var loot_spawn_points: Array[Node3D] = []

var cleared: bool = false
var encounter_active: bool = false

func get_random_enemy_spawn() -> Vector3:
    if enemy_spawn_points.is_empty():
        return global_position + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
    var sp = enemy_spawn_points.pick_random()
    return sp.global_position

func on_cleared():
    cleared = true
    encounter_active = false
```

### EncounterTrigger.gd

```gdscript
class_name EncounterTrigger
extends Area3D

signal encounter_started(room: Room)

@export var room: Room

func _ready():
    body_entered.connect(_on_body_entered)

func _on_body_entered(body):
    if body is PlayerController and not room.cleared:
        room.encounter_active = true
        encounter_started.emit(room)
```

### Corridor System

Corridors connect rooms. Each corridor is a straight segment with:
- Narrow walls (width 4 units)
- Floor with nav mesh
- Optional torch placements
- Doorways at each end

Corridor generation uses the existing `CD` (corridor depth) pattern from DungeonView3D.

---

## Phase 6 — Combat Integration (3D ↔ Card System)

### Data Flow

```
3D World
  │
  ├── PlayerController walks into EncounterTrigger
  │     │
  │     ▼
  ├── EncounterTrigger.emit("encounter_started")
  │     │
  │     ▼
  ├── CombatManager3D.start_3d_combat(monsters)
  │     │
  │     ├── Lock player movement
  │     ├── Play "combat start" animation
  │     ├── Spawn enemy models at positions
  │     │
  │     ▼
  ├── CombatManager3D transitions to card combat
  │     │
  │     ├── Camera switches to combat view
  │     ├── CardCombatUI appears (overlay)
  │     │
  │     ▼
  ├── CombatSystem.process_player_action(action, target)
  │     │
  │     ├── On hit: play attack animation on player model
  │     ├── Play hit reaction on enemy model
  │     ├── Update HP bars (3D & UI)
  │     │
  │     ├── On enemy turn: enemy plays attack animation
  │     │   Player model plays hit reaction
  │     │
  │     ▼
  ├── Combat ends
  │     │
  │     ├── Victory: play death animation on enemies, 
  │     │   grant loot, unlock movement
  │     ├── Flee: unlock movement, return to exploration
  │     └── Defeat: trigger game over
  │
  ▼
Return to 3D exploration
```

### CombatManager3D.gd

```gdscript
class_name CombatManager3D
extends Node

signal combat_finished(result: Dictionary)

var player: PlayerController
var enemies_3d: Array[EnemyBase] = []
var is_in_combat: bool = false

func _ready():
    player = get_tree().get_first_node_in_group("player")

func start_3d_combat(monster_datas: Array[MonsterData], room: Room):
    is_in_combat = true
    player.set_movement_locked(true)
    
    # Spawn 3D enemies in room
    for i in range(monster_datas.size()):
        var spawn_pos = room.get_random_enemy_spawn()
        var enemy = EnemyFactory.spawn_enemy(monster_datas[i], spawn_pos, room)
        enemy.died.connect(_on_enemy_died)
        enemies_3d.append(enemy)
    
    # Bridge to existing CombatSystem
    GameManager.start_combat(monster_datas)
    
    # Show card combat UI overlay
    var card_ui = preload("res://scenes/ui/CardCombatUI.tscn").instantiate()
    add_child(card_ui)
    card_ui.setup(GameManager.combat, enemies_3d)
    card_ui.combat_resolved.connect(_on_combat_resolved)

func _on_combat_resolved(result: Dictionary):
    if result.get("victory", false):
        for enemy in enemies_3d:
            enemy.die()
    elif result.get("fled", false):
        for enemy in enemies_3d:
            enemy.queue_free()
    
    is_in_combat = false
    player.set_movement_locked(false)
    combat_finished.emit(result)
```

### CardCombatUI.gd (3D-aware overlay)

```gdscript
extends Control

signal combat_resolved(result: Dictionary)

var combat_system: CombatSystem
var enemies_3d: Array[EnemyBase]

func setup(combat: CombatSystem, enemies: Array[EnemyBase]):
    combat_system = combat
    enemies_3d = enemies
    # Build the card UI — reuse existing CardUI scenes as children
    # Show action buttons, enemy HP bars, etc.
    
func _on_player_action(action_id: String, target_index: int):
    var result = combat_system.process_player_action(action_id, target_index)
    if result.get("success", false):
        animate_attack(target_index)
        await get_tree().create_timer(0.5).timeout
        var enemy_messages = combat_system.process_enemy_turn()
        animate_enemy_attacks(enemy_messages)
    
    if combat_system.get_state() == 3: # VICTORY
        var result_data = combat_system.end_combat()
        combat_resolved.emit({"victory": true, "result": result_data})
    elif combat_system.get_state() == 4: # DEFEAT
        combat_resolved.emit({"victory": false, "defeat": true})

func animate_attack(target_index: int):
    if target_index >= 0 and target_index < enemies_3d.size():
        var enemy = enemies_3d[target_index]
        enemy.play_hit_reaction()
        player.play_attack_animation()

func animate_enemy_attacks(messages: Array):
    for msg in messages:
        if msg.get("type") == "damage":
            player.play_hit_reaction()
```

---

## Phase 7 — UI System (3D Overlay)

All UI is Control-based overlaying the 3D viewport. The root scene is:

```
GameWorld (Node)
├── World3D (Node3D)
│   ├── DirectionalLight3D
│   ├── WorldEnvironment
│   ├── DungeonWorld
│   └── Player
├── UILayer (CanvasLayer)
│   ├── HUD (HP bar, gold, floor, minimap)
│   ├── InteractionPrompt (contextual "Press E to...")
│   └── CardCombatUI (shown during combat)
└── WorldAudio (AudioStreamPlayer3D)
```

### HUD Overlay (existing scenes adapted)

The existing HUD.gd, GameBoard.gd, etc. are repurposed as UILayer children. Only show when relevant (e.g., CardCombatUI only during combat).

### Navigation through 3D → Combat → Result

1. Player walks into enemy → EncounterTrigger fires
2. CombatManager3D takes over → shows CardCombatUI
3. Card combat resolves using existing CombatSystem
4. On victory: play death anims, enemies disappear, spawn loot
5. Player can walk to next room's encounter trigger

---

## Phase 8 — Implementation Order

### Step 1: Project setup (Day 1)
- Create folder structure
- Update project.godot (3D settings)
- Set up physics/collision layers
- Create root GameWorld.tscn scene

### Step 2: Player (Day 2-3)
- Create Player.tscn with CharacterBody3D
- Implement PlayerController.gd (movement)
- Implement PlayerCamera.gd (third-person camera with zoom)
- Set up Input Map
- Import Quaternius character model
- Set up AnimationTree

### Step 3: Dungeon rooms (Day 4-5)
- Create modular Room.tscn prefab
- Create room variants (monster, treasure, rest, boss)
- Implement DungeonWorld.gd
- Implement RoomGenerator.gd
- Set up NavigationRegion3D
- Bake navigation mesh

### Step 4: Enemy system (Day 6-8)
- Create StateMachine.gd
- Implement all states (Idle, Patrol, Chase, Attack, Return, Death)
- Create EnemyBase.tscn
- Import enemy models (Goblin, Skeleton, Slime, Cultist, Demon)
- Set up enemy AnimationTrees with Mixamo anims
- Implement EnemyFactory.gd

### Step 5: Combat bridge (Day 9-10)
- Create CombatManager3D.gd
- Create CardCombatUI overlay
- Connect 3D triggers to card combat
- Test full combat flow (trigger → combat → victory → loot)

### Step 6: Polish (Day 11-14)
- Add ambient audio (footsteps, dungeon ambience)
- Add particle effects (torches, magic, damage numbers)
- Add loot pickups (3D chests)
- Add minimap / floor indicator
- Performance optimization (occlusion culling, LODs)
- Controller support testing

---

## Performance Optimization Checklist

- [ ] Enable OcclusionCulling in WorldEnvironment
- [ ] Set up Occluder3D nodes on walls and large geometry
- [ ] Use VisibilityNotifier3D to disable distant enemies
- [ ] Set `mesh/size/vertex_compress` on imported models
- [ ] Use ImporterMesh for static geometry
- [ ] Bake lighting (use LightmapGI for dungeons)
- [ ] Reduce shadow map size on secondary lights
- [ ] Use `rendering/quality/shadow_atlas/size=2048`
- [ ] Set `rendering/limits/time/time_rollover=0.5` for mobile renderer
- [ ] Pool enemy instances (don't instantiate/free mid-combat)
- [ ] Use GPUParticles3D with fixed FPS for torch/smoke
- [ ] LOD: Use simplified meshes for distant rooms
- [ ] Texture atlas: Combine dungeon textures into atlas
- [ ] Set `NavigationServer3D` cell size to 0.5 for performance

---

## Scene Hierarchy Diagram

```
GameWorld.tscn
│
├── World3D (Node3D)
│   ├── DirectionalLight3D
│   │   ├── rotation: -45° pitch, 30° yaw
│   │   └── shadow_enabled: true
│   ├── WorldEnvironment
│   │   ├── Environment (fog, tonemap, ambient)
│   │   └── 
│   ├── DungeonWorld (Node3D)
│   │   ├── Room_0 (Room.tscn)
│   │   │   ├── Walls/Floor/Ceiling (StaticBody3D)
│   │   │   ├── NavigationRegion3D
│   │   │   ├── EnemySpawn (Marker3D) × N
│   │   │   ├── LootSpawn (Marker3D) × N
│   │   │   └── EncounterTrigger (Area3D)
│   │   ├── Corridor_0 (Corridor.tscn)
│   │   │   ├── Walls (StaticBody3D)
│   │   │   ├── Floor (NavigationRegion3D)
│   │   │   └── Torch_0..N (Node3D + OmniLight3D + GPUParticles3D)
│   │   ├── Room_1 (Room.tscn)
│   │   └── ...
│   │
│   └── Player (CharacterBody3D)
│       ├── CollisionShape3D
│       ├── Model (Imported GLB)
│       ├── AnimationTree
│       ├── SpringArm3D
│       │   └── Camera3D
│       ├── InteractionZone (Area3D)
│       └── CombatZone (Area3D)
│
├── UILayer (CanvasLayer)
│   ├── HUD (Control)
│   │   ├── HPBar
│   │   ├── GoldLabel
│   │   ├── FloorLabel
│   │   └── MiniMap
│   ├── InteractionPrompt (Control)
│   ├── CardCombatUI (Control, visible during combat)
│   └── PauseMenu (Control)
│
└── Audio (Node)
    ├── MusicPlayer (AudioStreamPlayer)
    ├── SFXPlayer (AudioStreamPlayer3D)
    └── AmbientPlayer (AudioStreamPlayer3D)
```

---

## Existing Code Preservation

The following files remain **completely unchanged**:
- `Scripts/CardData.gd` — Card data model
- `Scripts/CardUI.gd` — Card visual component (used in combat UI)
- `Scripts/CombatSystem.gd` — Turn-based combat engine
- `Scripts/DeckManager.gd` — Deck building and drawing
- `Scripts/DungeonManager.gd` — Room/floor generation logic
- `Scripts/GameManager.gd` — Game state orchestration (minor additions only)
- `Scripts/PlayerData.gd` — Player stats data (no scene representation)
- `Scripts/MonsterData.gd` — Monster data (used by EnemyFactory)
- `Scripts/ShieldData.gd` — Shield card data
- `Scripts/LootSystem.gd` — Loot generation
- `Scripts/ShopManager.gd` — Shop logic
- `Scripts/RoguelikeManager.gd` — Meta-progression
- `Scripts/StatusManager.gd` — Status effects
- `Scripts/NarrationManager.gd` — Text narration
- `Scripts/MusicManager.gd` — Music playback
- `Scripts/TTSManager.gd` — Text-to-speech
- `Data/*.json` — All game data
- `Scenes/Card.tscn`, `Scenes/TitleScreen.tscn`, `Scenes/ClassSelect.tscn`,
  `Scenes/GameOver.tscn`, `Scenes/Shop.tscn` — Keep as 2D fallback / menu screens

**Files that get minor additions:**
- `Scripts/GameManager.gd` — Add `start_3d_mode()` and `set_movement_locked()` methods

**Files that are replaced/reworked:**
- `Scenes/GameBoard.tscn` and `Scripts/GameBoard.gd` — Replaced by `GameWorld.tscn`
- `Scripts/DungeonView3D.gd` — The SubViewport approach is replaced by real 3D scenes

---

## Controller Support

Built into PlayerController via Input Map:
- Left stick: movement (analog)
- Right stick: camera look
- A button: interact
- X button: attack
- B button: dodge/roll
- Start: pause menu
- Triggers: ability 1 / ability 2

---

## Future Multiplayer Architecture

The modular design supports adding multiplayer later:

```
GameManager (replicated)
├── PlayerData (per peer)
├── CombatSystem (authoritative server)
├── DungeonWorld (synchronized)
│   ├── EnemyBase (synchronized via state)
│   └── Room (synchronized via RPC)
└── LootSystem (authoritative)
```

All game logic is already data-driven (JSON) and manager-based. Adding multiplayer requires:
1. Convert `GameManager` to a replicated node
2. Make `PlayerData` a `Resource` with `@export` for replication
3. Make `CombatSystem` authority-checked
4. Add `MultiplayerSynchronizer` to Player and EnemyBase
5. Use RPCs for combat actions and room transitions
