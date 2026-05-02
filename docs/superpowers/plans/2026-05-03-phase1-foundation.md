# TowerHell Phase 1: Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Un progetto Godot 4.6 eseguibile dove il mago si muove lungo il cerchio blu, l'aim-star segue il mouse/joystick, il cerchio magico ha HP, e gli Orc nemici spawnano e camminano verso la torre finché la distruggono.

**Architecture:** Scene-per-entity. `GameManager` e `SignalBus` come Autoloads. `Arena` è la scena root che contiene tutto. Il mago è vincolato al cerchio via angolo trigonometrico. I nemici seguono la torre con movimento diretto (senza NavigationAgent2D — aggiunto in Phase 2 quando servono ostacoli).

**Tech Stack:** Godot 4.6, GDScript con static typing, GUT plugin per test logica, `CharacterBody2D` per entità mobili.

**Repo:** `C:/Users/mikbio/documents/TowerHell` (git già inizializzato)

---

## File Structure

```
res://
├── project.godot                      # Godot project config
├── addons/gut/                        # GUT test plugin (installato in Task 1)
├── autoloads/
│   ├── SignalBus.gd                   # Segnali globali
│   └── GameManager.gd                 # Stato run: HP, livello, fase
├── scenes/
│   ├── world/
│   │   ├── Arena.tscn                 # Scena root di gioco
│   │   └── Arena.gd
│   ├── tower/
│   │   ├── Tower.tscn                 # Torre centrale (Area2D + sprite)
│   │   ├── Tower.gd
│   │   ├── MagicCircle.tscn           # Cerchio magico con HP
│   │   └── MagicCircle.gd
│   ├── player/
│   │   ├── Wizard.tscn                # Player (CharacterBody2D)
│   │   └── Wizard.gd
│   ├── enemies/
│   │   ├── Orc.tscn                   # Nemico Orc (CharacterBody2D)
│   │   └── Orc.gd
│   └── ui/
│       ├── HUD.tscn                   # HUD overlay
│       └── HUD.gd
├── tests/
│   ├── test_game_manager.gd           # Test logica GameManager
│   └── test_magic_circle.gd          # Test HP/danno cerchio
└── sprites/                           # (già presenti)
```

---

## Task 1: Godot Project Setup + GUT Plugin

**Files:**
- Create: `project.godot`
- Create: `addons/gut/` (download plugin)

- [ ] **Step 1: Inizializza il progetto Godot**

Apri Godot 4.6. Click **New Project** → nome `TowerHell` → seleziona `C:/Users/mikbio/documents/TowerHell` come path → **2D** → **Create & Edit**.

Godot creerà automaticamente `project.godot` nella directory.

- [ ] **Step 2: Configura project.godot**

In **Project > Project Settings**:
- **Display > Window > Size:** Width `1280`, Height `720`
- **Display > Window > Stretch > Mode:** `canvas_items`
- **Display > Window > Stretch > Aspect:** `keep`
- **Rendering > 2D > Snap > Snap 2D Transforms to Pixel:** `On`

- [ ] **Step 3: Installa GUT**

Scarica GUT da AssetLib in Godot: **AssetLib** (tab in alto) → cerca "GUT" → installa **Gut - Godot Unit Testing**.

Oppure manualmente: scarica la release da `https://github.com/bitwes/Gut/releases` e decomprimi nella cartella `addons/gut/`.

Poi in **Project > Project Settings > Plugins** → abilita **GUT**.

- [ ] **Step 4: Crea struttura cartelle**

In Godot FileSystem (pannello basso sinistra), crea le cartelle:
`autoloads/`, `scenes/world/`, `scenes/tower/`, `scenes/player/`, `scenes/enemies/`, `scenes/ui/`, `tests/`

- [ ] **Step 5: Commit**

```bash
cd "C:/Users/mikbio/documents/TowerHell"
git add project.godot addons/ .gitignore
git commit -m "feat: initialize Godot 4.6 project with GUT plugin"
git push
```

---

## Task 2: SignalBus + GameManager Autoloads

**Files:**
- Create: `autoloads/SignalBus.gd`
- Create: `autoloads/GameManager.gd`

- [ ] **Step 1: Crea SignalBus.gd**

Crea `autoloads/SignalBus.gd`:

```gdscript
extends Node

# Tower / Circle
signal circle_damaged(amount: float)
signal circle_destroyed()

# Enemies
signal enemy_died(enemy_position: Vector2, soul_value: int, gold_value: int)
signal enemy_reached_tower()

# Player / Spells
signal spell_cast(element: String, position: Vector2)
signal player_leveled_up(new_level: int)

# Economy
signal souls_changed(new_amount: int)
signal gold_changed(new_amount: int)

# Waves
signal wave_started(wave_number: int)
signal corrupted_night_started()
signal corrupted_night_ended()
```

- [ ] **Step 2: Crea GameManager.gd**

Crea `autoloads/GameManager.gd`:

```gdscript
extends Node

const CIRCLE_MAX_HP: float = 100.0
const EXP_PER_LEVEL: float = 100.0
const EXP_MULTIPLIER: float = 1.2  # each level needs 20% more EXP

var circle_hp: float = CIRCLE_MAX_HP
var player_level: int = 1
var player_exp: float = 0.0
var exp_to_next_level: float = EXP_PER_LEVEL
var is_run_active: bool = false

func start_run() -> void:
    circle_hp = CIRCLE_MAX_HP
    player_level = 1
    player_exp = 0.0
    exp_to_next_level = EXP_PER_LEVEL
    is_run_active = true

func damage_circle(amount: float) -> void:
    circle_hp = maxf(0.0, circle_hp - amount)
    SignalBus.circle_damaged.emit(amount)
    if circle_hp <= 0.0:
        is_run_active = false
        SignalBus.circle_destroyed.emit()

func add_exp(amount: float) -> void:
    player_exp += amount
    while player_exp >= exp_to_next_level:
        player_exp -= exp_to_next_level
        player_level += 1
        exp_to_next_level *= EXP_MULTIPLIER
        SignalBus.player_leveled_up.emit(player_level)

func get_circle_hp_percent() -> float:
    return circle_hp / CIRCLE_MAX_HP
```

- [ ] **Step 3: Registra gli Autoloads**

In **Project > Project Settings > Autoload**:
- Aggiungi `autoloads/SignalBus.gd` con nome `SignalBus`
- Aggiungi `autoloads/GameManager.gd` con nome `GameManager`

Assicurati che `SignalBus` sia **sopra** `GameManager` nella lista (viene caricato prima).

- [ ] **Step 4: Scrivi i test**

Crea `tests/test_game_manager.gd`:

```gdscript
extends GutTest

func before_each() -> void:
    GameManager.start_run()

func test_start_run_resets_hp() -> void:
    GameManager.damage_circle(50.0)
    GameManager.start_run()
    assert_eq(GameManager.circle_hp, GameManager.CIRCLE_MAX_HP)

func test_damage_circle_reduces_hp() -> void:
    GameManager.damage_circle(30.0)
    assert_eq(GameManager.circle_hp, 70.0)

func test_damage_circle_cannot_go_below_zero() -> void:
    GameManager.damage_circle(200.0)
    assert_eq(GameManager.circle_hp, 0.0)

func test_circle_destroyed_signal_emitted() -> void:
    watch_signals(SignalBus)
    GameManager.damage_circle(GameManager.CIRCLE_MAX_HP)
    assert_signal_emitted(SignalBus, "circle_destroyed")

func test_level_up_on_exp_gain() -> void:
    GameManager.add_exp(GameManager.EXP_PER_LEVEL)
    assert_eq(GameManager.player_level, 2)

func test_exp_overflow_carries_to_next_level() -> void:
    GameManager.add_exp(GameManager.EXP_PER_LEVEL * 2.5)
    assert_eq(GameManager.player_level, 3)
```

- [ ] **Step 5: Esegui i test**

In Godot: **Project > Tools > GUT** → click **Run All** → tutti i test devono passare (verde).

- [ ] **Step 6: Commit**

```bash
git add autoloads/ tests/test_game_manager.gd
git commit -m "feat: add SignalBus and GameManager autoloads with tests"
git push
```

---

## Task 3: Arena Scene (Sfondo + Cerchi Visivi)

**Files:**
- Create: `scenes/world/Arena.tscn`
- Create: `scenes/world/Arena.gd`

- [ ] **Step 1: Crea Arena.tscn**

In Godot, crea una nuova scena: **Scene > New Scene** → root node `Node2D` → rinomina in `Arena`.

Struttura nodi:
```
Arena (Node2D)
├── Background (Sprite2D)          ← sprites/background/background.png
├── Circles (Node2D)               ← contenitore cerchi (disegnati via script)
└── Entities (Node2D)              ← conterrà Torre, Mago, Nemici
```

Salva come `scenes/world/Arena.tscn`.

- [ ] **Step 2: Configura Background**

Seleziona il nodo `Background`:
- **Texture:** trascina `sprites/background/background.png`
- **Position:** `(0, 0)` (centro scena)

In **Project Settings > Display > Window**: assicurati che la viewport sia `1280x720`. Il background deve coprire l'intera finestra.

- [ ] **Step 3: Crea Arena.gd con disegno cerchi**

Crea `scenes/world/Arena.gd`:

```gdscript
extends Node2D

# Raggi in pixel — calibra in base alla risoluzione
const TOWER_RADIUS: float = 40.0        # torre centrale
const WIZARD_CIRCLE_RADIUS: float = 130.0   # cerchio blu (percorso mago)
const BARRIER_CIRCLE_RADIUS: float = 220.0  # cerchio rosso (confine)

const COLOR_WIZARD_CIRCLE: Color = Color(0.2, 0.5, 1.0, 0.8)
const COLOR_BARRIER_CIRCLE: Color = Color(0.7, 0.0, 0.0, 0.6)
const LINE_WIDTH: float = 3.0

@onready var circles: Node2D = $Circles

func _ready() -> void:
    # Centra l'arena al centro della viewport
    var viewport_size := get_viewport_rect().size
    position = viewport_size / 2.0

func _draw() -> void:
    # Cerchio percorso mago (blu)
    draw_arc(Vector2.ZERO, WIZARD_CIRCLE_RADIUS, 0.0, TAU, 64,
             COLOR_WIZARD_CIRCLE, LINE_WIDTH)
    # Cerchio barriera (rosso tratteggiato)
    _draw_dashed_circle(Vector2.ZERO, BARRIER_CIRCLE_RADIUS,
                        COLOR_BARRIER_CIRCLE, LINE_WIDTH)

func _draw_dashed_circle(center: Vector2, radius: float,
                          color: Color, width: float) -> void:
    var segments: int = 32
    var dash_ratio: float = 0.6  # 60% pieno, 40% vuoto
    for i in segments:
        var angle_start := (TAU / segments) * i
        var angle_end := angle_start + (TAU / segments) * dash_ratio
        var p1 := center + Vector2(cos(angle_start), sin(angle_start)) * radius
        var p2 := center + Vector2(cos(angle_end), sin(angle_end)) * radius
        draw_line(p1, p2, color, width)
```

- [ ] **Step 4: Assegna lo script e imposta la scena come principale**

Seleziona il nodo `Arena` → trascina `Arena.gd` nel campo **Script**.

In **Project > Project Settings > Application > Run > Main Scene**: seleziona `scenes/world/Arena.tscn`.

- [ ] **Step 5: Verifica visiva**

Premi **F5** (Run Project). Devi vedere:
- Sfondo della mappa
- Cerchio blu continuo al centro
- Cerchio rosso tratteggiato più grande intorno

Se i cerchi non sono centrati, controlla che `_ready()` calcoli bene la viewport size.

- [ ] **Step 6: Commit**

```bash
git add scenes/world/
git commit -m "feat: add Arena scene with visual circles (wizard path + barrier)"
git push
```

---

## Task 4: Tower + MagicCircle

**Files:**
- Create: `scenes/tower/Tower.tscn` + `Tower.gd`
- Create: `scenes/tower/MagicCircle.tscn` + `MagicCircle.gd`
- Create: `tests/test_magic_circle.gd`

- [ ] **Step 1: Crea Tower.tscn**

Nuova scena → root `Area2D` → rinomina `Tower`.

Struttura:
```
Tower (Area2D)
├── Sprite2D                ← placeholder: un esagono viola (DrawCircle via script per ora)
└── CollisionShape2D        ← CircleShape2D, radius 40
```

Script `Tower.gd`:

```gdscript
extends Area2D

const TOWER_RADIUS: float = 40.0

func _draw() -> void:
    # Placeholder visivo torre — hexagram stilizzato
    var points: PackedVector2Array = []
    for i in 6:
        var angle := (PI / 3.0) * i - PI / 6.0
        points.append(Vector2(cos(angle), sin(angle)) * TOWER_RADIUS)
    draw_colored_polygon(points, Color(0.3, 0.0, 0.5, 0.9))
    draw_polyline(points + PackedVector2Array([points[0]]),
                  Color(0.6, 0.2, 1.0), 3.0)
```

Salva come `scenes/tower/Tower.tscn`.

- [ ] **Step 2: Crea MagicCircle.tscn**

Nuova scena → root `Node2D` → rinomina `MagicCircle`.

Struttura:
```
MagicCircle (Node2D)
└── CrackOverlay (Sprite2D)    ← sprites/UI/ui_elements/Decorative_cracks.png (inizialmente invisible)
```

Script `MagicCircle.gd`:

```gdscript
extends Node2D

const MAX_HP: float = 100.0
const CIRCLE_RADIUS: float = 220.0
const CRACK_THRESHOLD_1: float = 0.66  # prime crepe a 66% HP
const CRACK_THRESHOLD_2: float = 0.33  # crepe pesanti a 33% HP

var current_hp: float = MAX_HP

@onready var crack_overlay: Sprite2D = $CrackOverlay

func _ready() -> void:
    SignalBus.circle_damaged.connect(_on_circle_damaged)
    crack_overlay.visible = false

func _on_circle_damaged(_amount: float) -> void:
    current_hp = GameManager.circle_hp
    _update_crack_visual()
    queue_redraw()

func _update_crack_visual() -> void:
    var pct := GameManager.get_circle_hp_percent()
    if pct <= CRACK_THRESHOLD_2:
        crack_overlay.visible = true
        crack_overlay.modulate.a = 1.0
    elif pct <= CRACK_THRESHOLD_1:
        crack_overlay.visible = true
        crack_overlay.modulate.a = 0.5
    else:
        crack_overlay.visible = false

func _draw() -> void:
    var pct := GameManager.get_circle_hp_percent()
    # Colore del cerchio scala da verde → rosso con il danno
    var circle_color := Color(1.0 - pct, pct * 0.5, 0.8, 0.7)
    draw_arc(Vector2.ZERO, CIRCLE_RADIUS, 0.0, TAU * pct, 64,
             circle_color, 6.0)
    # Arco vuoto (danno)
    draw_arc(Vector2.ZERO, CIRCLE_RADIUS, TAU * pct, TAU, 64,
             Color(0.3, 0.0, 0.0, 0.4), 6.0)
```

- [ ] **Step 3: Test MagicCircle**

Crea `tests/test_magic_circle.gd`:

```gdscript
extends GutTest

func before_each() -> void:
    GameManager.start_run()

func test_hp_percent_full() -> void:
    assert_eq(GameManager.get_circle_hp_percent(), 1.0)

func test_hp_percent_half() -> void:
    GameManager.damage_circle(50.0)
    assert_almost_eq(GameManager.get_circle_hp_percent(), 0.5, 0.001)

func test_hp_percent_zero() -> void:
    GameManager.damage_circle(999.0)
    assert_eq(GameManager.get_circle_hp_percent(), 0.0)
```

- [ ] **Step 4: Esegui test**

GUT → Run All → verde.

- [ ] **Step 5: Aggiungi Tower e MagicCircle all'Arena**

In `Arena.tscn`, seleziona il nodo `Entities` e aggiungi come istanze:
- `scenes/tower/Tower.tscn` → position `(0, 0)` (l'Arena è già centrata)
- `scenes/tower/MagicCircle.tscn` → position `(0, 0)`

- [ ] **Step 6: Chiama start_run() in Arena._ready()**

In `Arena.gd` aggiungi in `_ready()`:

```gdscript
func _ready() -> void:
    var viewport_size := get_viewport_rect().size
    position = viewport_size / 2.0
    GameManager.start_run()
```

- [ ] **Step 7: Verifica visiva**

**F5** → devi vedere la torre hexagon viola al centro, il cerchio magico color-coded intorno. Nessun crash.

- [ ] **Step 8: Commit**

```bash
git add scenes/tower/ tests/test_magic_circle.gd
git commit -m "feat: add Tower and MagicCircle with HP visual feedback"
git push
```

---

## Task 5: Wizard — Movimento sul Cerchio

**Files:**
- Create: `scenes/player/Wizard.tscn`
- Create: `scenes/player/Wizard.gd`

- [ ] **Step 1: Configura Input Map**

In **Project > Project Settings > Input Map**, aggiungi queste azioni (click **Add New Action**):

| Action name     | Default binding      |
|-----------------|----------------------|
| `move_left`     | Key A, Key Left      |
| `move_right`    | Key D, Key Right     |
| `ui_cancel`     | Esc                  |

Per mobile (aggiungi dopo i test su PC):
- `move_left` / `move_right` saranno gestiti via joystick virtuale (Phase 4)

- [ ] **Step 2: Crea Wizard.tscn**

Nuova scena → root `CharacterBody2D` → rinomina `Wizard`.

Struttura:
```
Wizard (CharacterBody2D)
├── Sprite2D          ← placeholder: cerchio azzurro (script draw)
├── CollisionShape2D  ← CircleShape2D, radius 16
└── AimIndicator (Line2D)   ← linea sottile verso l'aim-star (debug, rimuovere dopo)
```

- [ ] **Step 3: Crea Wizard.gd**

Crea `scenes/player/Wizard.gd`:

```gdscript
extends CharacterBody2D

const CIRCLE_RADIUS: float = 130.0   # deve corrispondere ad Arena.WIZARD_CIRCLE_RADIUS
const MOVE_SPEED: float = 2.5        # radianti per secondo

var _angle: float = 0.0              # angolo corrente sul cerchio (radianti)

func _ready() -> void:
    _update_position()

func _physics_process(delta: float) -> void:
    var input_dir: float = Input.get_axis("move_left", "move_right")
    if input_dir != 0.0:
        _angle += input_dir * MOVE_SPEED * delta
        _angle = fmod(_angle, TAU)   # mantieni in [0, TAU)
        _update_position()
    _face_aim_star()

func _update_position() -> void:
    # Posizione relativa al parent (Arena centrata a viewport/2)
    position = Vector2(cos(_angle), sin(_angle)) * CIRCLE_RADIUS

func _face_aim_star() -> void:
    # Il mago guarda verso la posizione globale del mouse
    # AimStar verrà aggiunto in Task 6 — per ora usa il mouse direttamente
    var aim_pos := get_global_mouse_position()
    var parent_global := get_parent().global_position if get_parent() else Vector2.ZERO
    # aim_pos è già in coordinate globali, convertiamo in locali dell'Arena
    look_at(aim_pos)

func _draw() -> void:
    # Placeholder sprite mago — cerchio azzurro con indicatore direzionale
    draw_circle(Vector2.ZERO, 16.0, Color(0.2, 0.6, 1.0))
    draw_line(Vector2.ZERO, Vector2(20, 0), Color(1.0, 1.0, 0.5), 3.0)
```

- [ ] **Step 4: Aggiungi Wizard all'Arena**

In `Arena.tscn` → `Entities` → instanzia `scenes/player/Wizard.tscn`.

Position: `(0, 0)` — il wizard si posizionerà sul cerchio tramite `_update_position()`.

- [ ] **Step 5: Verifica**

**F5** → il wizard (cerchio azzurro) deve:
- Apparire sul cerchio blu
- Muoversi lungo il cerchio con A/D o frecce sinistra/destra
- Ruotare verso il mouse

- [ ] **Step 6: Commit**

```bash
git add scenes/player/ project.godot
git commit -m "feat: add Wizard with circular movement and mouse facing"
git push
```

---

## Task 6: AimStar (Cursore Magico)

**Files:**
- Create: `scenes/player/AimStar.tscn`
- Create: `scenes/player/AimStar.gd`

- [ ] **Step 1: Crea AimStar.tscn**

Nuova scena → root `Node2D` → rinomina `AimStar`.

Struttura:
```
AimStar (Node2D)
└── (tutto disegnato via _draw)
```

- [ ] **Step 2: Crea AimStar.gd**

Crea `scenes/player/AimStar.gd`:

```gdscript
extends Node2D

const INNER_RADIUS: float = 8.0
const OUTER_RADIUS: float = 18.0
const NUM_POINTS: int = 6        # stella a 6 punte
const ROTATION_SPEED: float = 1.5  # radianti/sec
const COLOR_BASE: Color = Color(1.0, 0.8, 0.1, 0.9)
const COLOR_GLOW: Color = Color(1.0, 0.5, 0.0, 0.4)

var _spin: float = 0.0

func _process(delta: float) -> void:
    _spin += ROTATION_SPEED * delta
    # In Godot 4, get_global_mouse_position() restituisce coordinate world space
    global_position = get_global_mouse_position()
    queue_redraw()

func _draw() -> void:
    # Glow esterno
    draw_circle(Vector2.ZERO, OUTER_RADIUS + 4.0, COLOR_GLOW)
    # Stella
    var points: PackedVector2Array = _build_star_points()
    draw_colored_polygon(points, COLOR_BASE)
    # Crosshair sottile
    draw_line(Vector2(-OUTER_RADIUS - 6, 0), Vector2(OUTER_RADIUS + 6, 0),
              Color(1, 1, 1, 0.5), 1.0)
    draw_line(Vector2(0, -OUTER_RADIUS - 6), Vector2(0, OUTER_RADIUS + 6),
              Color(1, 1, 1, 0.5), 1.0)

func _build_star_points() -> PackedVector2Array:
    var points: PackedVector2Array = []
    for i in NUM_POINTS * 2:
        var angle := (TAU / (NUM_POINTS * 2)) * i + _spin
        var r := OUTER_RADIUS if i % 2 == 0 else INNER_RADIUS
        points.append(Vector2(cos(angle), sin(angle)) * r)
    return points

func get_global_aim_position() -> Vector2:
    return global_position
```

- [ ] **Step 3: Nascondi il cursore di sistema**

In `Arena.gd` `_ready()`:

```gdscript
func _ready() -> void:
    var viewport_size := get_viewport_rect().size
    position = viewport_size / 2.0
    GameManager.start_run()
    Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
```

- [ ] **Step 4: Aggiungi AimStar all'Arena**

In `Arena.tscn` → `Entities` → instanzia `scenes/player/AimStar.tscn`.

**Importante:** AimStar deve essere l'**ultimo** nodo in `Entities` così viene disegnato sopra tutto.

- [ ] **Step 5: Aggiorna Wizard per usare AimStar**

In `Wizard.gd`, sostituisci `_face_aim_star()`:

```gdscript
@onready var _aim_star: Node2D = null

func _ready() -> void:
    _update_position()
    # Trova AimStar nel parent dopo che la scena è pronta
    await get_tree().process_frame
    _aim_star = get_parent().get_node_or_null("Entities/AimStar")

func _face_aim_star() -> void:
    if _aim_star:
        look_at(_aim_star.global_position)
    else:
        look_at(get_global_mouse_position())
```

- [ ] **Step 6: Verifica**

**F5** → la stella gialla ruota e segue il mouse. Il cursore di sistema è nascosto. Il mago ruota verso la stella.

- [ ] **Step 7: Commit**

```bash
git add scenes/player/AimStar.tscn scenes/player/AimStar.gd
git commit -m "feat: add animated AimStar cursor following mouse"
git push
```

---

## Task 7: Enemy Orc (Pathfinding Base verso Torre)

**Files:**
- Create: `scenes/enemies/Orc.tscn`
- Create: `scenes/enemies/Orc.gd`

- [ ] **Step 1: Crea Orc.tscn**

Nuova scena → root `CharacterBody2D` → rinomina `Orc`.

Struttura:
```
Orc (CharacterBody2D)
├── AnimatedSprite2D          ← sprites Orc (Idle, Walk, Death, Hurt)
├── CollisionShape2D          ← CapsuleShape2D h=24 w=16
├── HealthBar (ProgressBar)   ← HP bar visibile sopra il nemico
└── HitArea (Area2D)
    └── CollisionShape2D      ← CircleShape2D radius=20 (per rilevare collisioni con magie)
```

- [ ] **Step 2: Configura AnimatedSprite2D**

Seleziona `AnimatedSprite2D` → **SpriteFrames** → New SpriteFrames.

Crea le animazioni (ogni animazione usa i frame in `sprites/characters/characters(100x100)/Orc/Orc with shadows/`):

| Animation | Frames | FPS | Loop |
|-----------|--------|-----|------|
| `idle`    | `Orc-Idle.png` (1 frame) | 8 | true |
| `walk`    | `Orc-Walk.png` (frame da sprite sheet) | 8 | true |
| `death`   | `Orc-Death.png` | 8 | false |
| `hurt`    | `Orc-Hurt.png` | 12 | false |

**Nota:** I file PNG contengono sprite sheet. Usa **Texture Region Editor** per definire le regioni o importa i singoli frame. Per ora usa 1 frame statico per ogni animazione — le animazioni complete vengono raffinate in Phase 4.

- [ ] **Step 3: Crea Orc.gd**

Crea `scenes/enemies/Orc.gd`:

```gdscript
extends CharacterBody2D

const SPEED: float = 60.0
const MAX_HP: float = 30.0
const SOUL_VALUE: int = 1
const GOLD_VALUE: int = 0     # Orc base non droppa oro (solo nemici elite)
const TOWER_DAMAGE: float = 10.0  # danno al cerchio magico al contatto
const EXP_VALUE: float = 10.0

var _hp: float = MAX_HP
var _tower_position: Vector2 = Vector2.ZERO
var _is_dead: bool = false

@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var _health_bar: ProgressBar = $HealthBar

func _ready() -> void:
    _health_bar.max_value = MAX_HP
    _health_bar.value = MAX_HP
    _anim.play("walk")

func setup(tower_global_pos: Vector2) -> void:
    _tower_position = tower_global_pos

func _physics_process(delta: float) -> void:
    if _is_dead:
        return
    var dir := (_tower_position - global_position).normalized()
    velocity = dir * SPEED
    move_and_slide()
    # Controlla se ha raggiunto la torre
    if global_position.distance_to(_tower_position) < 45.0:
        _reach_tower()

func take_damage(amount: float) -> void:
    if _is_dead:
        return
    _hp = maxf(0.0, _hp - amount)
    _health_bar.value = _hp
    if _hp <= 0.0:
        _die()
    else:
        _anim.play("hurt")
        await _anim.animation_finished
        _anim.play("walk")

func _die() -> void:
    _is_dead = true
    _anim.play("death")
    SignalBus.enemy_died.emit(global_position, SOUL_VALUE, GOLD_VALUE)
    GameManager.add_exp(EXP_VALUE)
    set_physics_process(false)
    await _anim.animation_finished
    queue_free()

func _reach_tower() -> void:
    _is_dead = true
    set_physics_process(false)
    GameManager.damage_circle(TOWER_DAMAGE)
    SignalBus.enemy_reached_tower.emit()
    queue_free()
```

- [ ] **Step 4: Configura HealthBar**

Seleziona `HealthBar` (ProgressBar):
- **Position:** `(-20, -35)` (sopra il nemico)
- **Size:** `40 x 6`
- **Show Percentage:** Off
- **Value:** `30` (MAX_HP)

In **Theme Override > Styles**: imposta `fill` color verde, `background` rosso scuro.

- [ ] **Step 5: Test istanza singola**

In `Arena.tscn`, aggiungi **temporaneamente** un'istanza di `Orc.tscn` in `Entities` con position `(300, 0)`. Aggiungi in `Arena.gd _ready()`:

```gdscript
# Test temporaneo — rimuovere dopo Task 8
var test_orc := preload("res://scenes/enemies/Orc.tscn").instantiate()
$Entities.add_child(test_orc)
test_orc.global_position = global_position + Vector2(300, 0)
test_orc.setup(global_position)  # Torre è al centro dell'Arena
```

- [ ] **Step 6: Verifica**

**F5** → l'Orc deve camminare verso il centro (dove c'è la torre) e quando arriva la torre deve perdere HP (visibile nel debug o nel cerchio).

- [ ] **Step 7: Rimuovi il test temporaneo**

Rimuovi il codice di test da `Arena.gd`.

- [ ] **Step 8: Commit**

```bash
git add scenes/enemies/
git commit -m "feat: add Orc enemy with direct pathfinding to tower and HP bar"
git push
```

---

## Task 8: WaveManager — Spawn Nemici

**Files:**
- Create: `autoloads/WaveManager.gd`

- [ ] **Step 1: Registra WaveManager come Autoload**

Crea prima il file, poi lo registri.

- [ ] **Step 2: Crea WaveManager.gd**

Crea `autoloads/WaveManager.gd`:

```gdscript
extends Node

const BASE_SPAWN_INTERVAL: float = 2.0   # secondi tra uno spawn e l'altro
const SPAWN_SCALE_INTERVAL: float = 60.0  # ogni 60s aumenta difficoltà
const SPAWN_SCALE_FACTOR: float = 0.9    # intervallo si riduce del 10% ogni scaling
const CORRUPTED_NIGHT_INTERVAL: float = 180.0  # ogni 3 minuti
const CORRUPTED_NIGHT_DURATION: float = 30.0
const SPAWN_RADIUS: float = 700.0        # distanza dal centro a cui spawnano i nemici
const ORC_SCENE: String = "res://scenes/enemies/Orc.tscn"

var _spawn_timer: float = 0.0
var _scale_timer: float = 0.0
var _corrupted_timer: float = 0.0
var _current_interval: float = BASE_SPAWN_INTERVAL
var _is_corrupted_night: bool = false
var _corrupted_remaining: float = 0.0
var _spawn_parent: Node2D = null
var _arena_center: Vector2 = Vector2.ZERO
var _orc_scene: PackedScene = null

func _ready() -> void:
    _orc_scene = load(ORC_SCENE)
    set_process(false)  # disabilitato finché start_waves() non viene chiamato

func start_waves(spawn_parent: Node2D, arena_center: Vector2) -> void:
    _spawn_parent = spawn_parent
    _arena_center = arena_center
    _current_interval = BASE_SPAWN_INTERVAL
    _spawn_timer = _current_interval
    _scale_timer = 0.0
    _corrupted_timer = 0.0
    _is_corrupted_night = false
    set_process(true)

func stop_waves() -> void:
    set_process(false)

func _process(delta: float) -> void:
    if not GameManager.is_run_active:
        stop_waves()
        return

    _spawn_timer -= delta
    _scale_timer += delta
    _corrupted_timer += delta

    # Scala difficoltà ogni 60s
    if _scale_timer >= SPAWN_SCALE_INTERVAL:
        _scale_timer = 0.0
        _current_interval = maxf(0.3, _current_interval * SPAWN_SCALE_FACTOR)

    # Corrupted Night ogni 3 minuti
    if not _is_corrupted_night and _corrupted_timer >= CORRUPTED_NIGHT_INTERVAL:
        _start_corrupted_night()

    if _is_corrupted_night:
        _corrupted_remaining -= delta
        if _corrupted_remaining <= 0.0:
            _end_corrupted_night()

    # Spawn
    if _spawn_timer <= 0.0:
        var interval := _current_interval / (3.0 if _is_corrupted_night else 1.0)
        _spawn_timer = interval
        _spawn_orc()

func _spawn_orc() -> void:
    if not _spawn_parent or not _orc_scene:
        return
    var orc: CharacterBody2D = _orc_scene.instantiate()
    _spawn_parent.add_child(orc)
    # Spawn in posizione random sul bordo del cerchio di spawn
    var angle := randf() * TAU
    orc.global_position = _arena_center + Vector2(cos(angle), sin(angle)) * SPAWN_RADIUS
    orc.setup(_arena_center)

func _start_corrupted_night() -> void:
    _is_corrupted_night = true
    _corrupted_remaining = CORRUPTED_NIGHT_DURATION
    _corrupted_timer = 0.0
    SignalBus.corrupted_night_started.emit()

func _end_corrupted_night() -> void:
    _is_corrupted_night = false
    SignalBus.corrupted_night_ended.emit()
```

- [ ] **Step 3: Registra WaveManager in Autoloads**

**Project > Project Settings > Autoload** → aggiungi `autoloads/WaveManager.gd` con nome `WaveManager`.

Ordine autoloads: `SignalBus` → `GameManager` → `WaveManager`.

- [ ] **Step 4: Avvia le onde dall'Arena**

In `Arena.gd`, aggiorna `_ready()`:

```gdscript
func _ready() -> void:
    var viewport_size := get_viewport_rect().size
    position = viewport_size / 2.0
    Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
    GameManager.start_run()
    # Avvia le onde — global_position è il centro dell'Arena
    WaveManager.start_waves($Entities, global_position)
    # Ferma le onde quando il cerchio è distrutto
    SignalBus.circle_destroyed.connect(_on_circle_destroyed)

func _on_circle_destroyed() -> void:
    WaveManager.stop_waves()
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    # TODO Phase 3: mostra schermata fine run
    print("GAME OVER — run terminata")
```

- [ ] **Step 5: Verifica**

**F5** → gli Orc devono spawnare dal bordo della mappa ogni ~2 secondi e camminare verso il centro. Dopo 60 secondi lo spawn accelera. La torre deve perdere HP quando gli Orc arrivano. Quando HP → 0, la console stampa "GAME OVER".

- [ ] **Step 6: Commit**

```bash
git add autoloads/WaveManager.gd project.godot
git commit -m "feat: add WaveManager with scaling spawn rate and Corrupted Night"
git push
```

---

## Task 9: HUD — HP Bar e Livello

**Files:**
- Create: `scenes/ui/HUD.tscn`
- Create: `scenes/ui/HUD.gd`

- [ ] **Step 1: Crea HUD.tscn**

Nuova scena → root `CanvasLayer` → rinomina `HUD`.

Struttura:
```
HUD (CanvasLayer)
├── CircleHPBar (ProgressBar)    ← barra HP cerchio magico
├── LevelLabel (Label)           ← "Livello: 1"
├── CorruptedNightLabel (Label)  ← "⚠ CORRUPTED NIGHT" (nascosto di default)
└── GameOverPanel (Panel)        ← pannello game over (nascosto di default)
    └── GameOverLabel (Label)    ← "TORRE DISTRUTTA"
```

- [ ] **Step 2: Configura nodi HUD**

`CircleHPBar`:
- **Anchor:** Top-Left → `(10, 10)` a `(250, 30)`
- **Max Value:** `100`
- **Value:** `100`

`LevelLabel`:
- **Anchor:** Top-Left → `(10, 40)`
- **Text:** `"Livello: 1"`

`CorruptedNightLabel`:
- **Anchor:** Top-Center, posizione verticale ~80px
- **Text:** `"⚠ CORRUPTED NIGHT ⚠"`
- **Modulate:** Color rosso acceso
- **Visible:** `false`

`GameOverPanel`:
- **Anchor:** Center, size `400x200`
- **Visible:** `false`

- [ ] **Step 3: Crea HUD.gd**

Crea `scenes/ui/HUD.gd`:

```gdscript
extends CanvasLayer

@onready var _hp_bar: ProgressBar = $CircleHPBar
@onready var _level_label: Label = $LevelLabel
@onready var _corrupted_label: Label = $CorruptedNightLabel
@onready var _game_over_panel: Panel = $GameOverPanel

func _ready() -> void:
    SignalBus.circle_damaged.connect(_on_circle_damaged)
    SignalBus.player_leveled_up.connect(_on_level_up)
    SignalBus.corrupted_night_started.connect(_on_corrupted_started)
    SignalBus.corrupted_night_ended.connect(_on_corrupted_ended)
    SignalBus.circle_destroyed.connect(_on_game_over)

func _on_circle_damaged(_amount: float) -> void:
    _hp_bar.value = GameManager.circle_hp

func _on_level_up(new_level: int) -> void:
    _level_label.text = "Livello: %d" % new_level

func _on_corrupted_started() -> void:
    _corrupted_label.visible = true

func _on_corrupted_ended() -> void:
    _corrupted_label.visible = false

func _on_game_over() -> void:
    _game_over_panel.visible = true
```

- [ ] **Step 4: Aggiungi HUD all'Arena**

In `Arena.tscn`, aggiungi come figlio diretto di `Arena` (non dentro `Entities`):
- Instanzia `scenes/ui/HUD.tscn`

Il `CanvasLayer` si sovrappone sempre alla scena 2D indipendentemente dalla posizione.

- [ ] **Step 5: Verifica**

**F5** →
- La barra HP è verde in alto a sinistra
- Quando un Orc raggiunge la torre, la barra scende
- Quando HP → 0, appare il pannello Game Over
- Durante Corrupted Night (dopo 3 min), appare il label rosso

- [ ] **Step 6: Commit**

```bash
git add scenes/ui/
git commit -m "feat: add HUD with HP bar, level display, and Corrupted Night indicator"
git push
```

---

## Task 10: Integration Test & Build Stabile

**Files:**
- Modify: `scenes/world/Arena.gd` (cleanup)

- [ ] **Step 1: Esegui GUT — tutti i test**

**Project > Tools > GUT > Run All**

Risultato atteso: tutti i test `test_game_manager.gd` e `test_magic_circle.gd` verdi.

- [ ] **Step 2: Playtest manuale — checklist**

Avvia il gioco con **F5** e verifica:

- [ ] Il mago (cerchio azzurro) si muove lungo il cerchio blu con A/D
- [ ] L'aim-star (stella gialla) segue il mouse
- [ ] Il mago ruota verso l'aim-star
- [ ] Gli Orc spawnano dal bordo ogni ~2 secondi
- [ ] Gli Orc camminano verso la torre
- [ ] Quando un Orc tocca la torre, la HP bar scende di 10
- [ ] La HP bar mostra correttamente la percentuale rimanente
- [ ] Il cerchio cambia colore man mano che perde HP
- [ ] Le crepe del `Decorative_cracks` appaiono sotto 66% HP
- [ ] Dopo 60s lo spawn accelera percettibilmente
- [ ] Quando HP → 0 appare il pannello "TORRE DISTRUTTA"
- [ ] La console non mostra errori GDScript

- [ ] **Step 3: Fix eventuali bug emersi dal playtest**

I bug più comuni a questo punto:
- **Orc non cammina:** verifica che `setup()` sia chiamato con le coordinate globali corrette dell'Arena
- **HP bar non si aggiorna:** verifica che `SignalBus.circle_damaged` sia connesso in HUD._ready()
- **Crash su `get_node_or_null`:** verifica il path del nodo AimStar in Wizard.gd

- [ ] **Step 4: Tag release Phase 1**

```bash
cd "C:/Users/mikbio/documents/TowerHell"
git add -A
git commit -m "feat: Phase 1 complete — playable foundation with wizard, enemies, waves, HUD

Core systems implemented:
- Arena with visual circles (wizard path + barrier)
- Tower + MagicCircle with HP and crack overlay
- Wizard circular movement with aim-star
- Orc enemy walking toward tower
- WaveManager with scaling difficulty + Corrupted Night
- HUD with HP bar and level display

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
git tag v0.1.0-phase1
git push && git push --tags
```

---

## Note per Phase 2

Phase 2 (Combat) partirà da questo stato funzionante e aggiungerà:
- 4 magie elementali con cast su aim-star (Fireball, Blizzard, StonePike, ArcaneBolt)
- Sistema danno magie → nemici (`HitArea` già presente sull'Orc)
- Drop Anime e Oro al kill (EconomyManager)
- Level-up perk selection UI (3 perk casuali)
- Animazioni Orc complete via SpriteFrames
- NavigationAgent2D per pathfinding attorno a ostacoli (prep terrain Phase 4)
