# Mérante — Handoff Godot 4

## Ce que c'est

Jeu d'exploration 2D side-scrolling. Le joueur incarne Ida, archéologue sous-marine, qui explore les ruines englouties de Mérante. Vision réduite à un cône de lumière, tout ce qu'Ida traverse se cartographie sur une mini-map persistante. Moteur : **Godot 4, renderer Compatibilité**.

---

## Structure du projet

Créer ces dossiers dans `res://` dès le début. Godot ne force pas une structure, mais celle-ci est cohérente avec la taille du projet.

```
res://
├── scenes/
│   ├── ida/
│   │   ├── ida.tscn
│   │   └── ida.gd
│   ├── creatures/
│   │   ├── sedentaire.tscn + sedentaire.gd
│   │   ├── errant.tscn + errant.gd
│   │   └── attire.tscn + attire.gd
│   ├── zones/
│   │   ├── port_exterieur.tscn
│   │   ├── rues_commercantes.tscn
│   │   └── port_interieur.tscn
│   └── ui/
│       ├── hud.tscn + hud.gd
│       ├── minimap.tscn + minimap.gd
│       └── carnet.tscn + carnet.gd
├── autoloads/
│   ├── game_state.gd       # Singleton — état global du jeu
│   ├── audio_manager.gd    # Singleton — gestion des ambiances sonores
│   └── narrative.gd        # Singleton — fragments trouvés, état d'Ida
├── assets/
│   ├── tilemaps/           # Tilesets pour les zones
│   └── audio/              # Fichiers audio .ogg
└── project.godot
```

**Les autoloads sont critiques.** Ce sont des singletons accessibles depuis n'importe quel script. Les déclarer dans `Projet > Paramètres du projet > Autoload` dès le début. Ils persistent entre les scènes — c'est ce qui permet à la mini-map et à l'état d'Ida de survivre aux transitions de zones.

---

## Le système de vision — la priorité absolue

C'est le cœur du jeu et la bonne nouvelle : Godot le gère nativement.

**Deux nœuds suffisent :**

`CanvasModulate` — un nœud dans la scène qui teinte tout le canvas d'une couleur. Réglé sur un noir quasi-total (`#0a0818`), il plonge tout dans l'obscurité.

`PointLight2D` — attaché à Ida. Crée un halo de lumière qui "perce" l'obscurité du CanvasModulate. C'est la lampe d'Ida.

```
Zone (Node2D)
├── CanvasModulate          ← color: #0a0818
├── TileMapLayer            ← les tuiles de la zone
├── Ida
│   └── PointLight2D        ← halo de lumière, suit Ida automatiquement
└── Creatures/
```

**Config du PointLight2D**
```
texture        : une image circulaire dégradée blanc → transparent (à créer)
texture_scale  : 3.0  (rayon du halo, ajuster selon le ressenti)
energy         : 1.2
color          : #f4a020  (ambre chaud)
blend_mode     : Add
```

Pour la texture du halo : dans Godot, créer un GradientTexture2D circulaire directement dans l'inspecteur — pas besoin d'image externe.

**Mode lampe faible** : `point_light.energy = 0.3` et `point_light.texture_scale = 0.8`. Les Attirés ne réagissent pas en dessous de `energy < 0.5`.

**La cartographie persistante** : un second système, séparé. Voir section MiniMap.

---

## Ida — scène et script

**Arbre de la scène `ida.tscn`**
```
CharacterBody2D  (ida.gd)
├── Sprite2D
├── CollisionShape2D     ← CapsuleShape2D, 16x32
├── PointLight2D         ← la lampe
├── RayCast2D × 4        ← détection des parois (haut, bas, gauche, droite)
└── Area2D               ← zone d'interaction avec les fragments narratifs
    └── CollisionShape2D
```

**ida.gd — mouvement underwater**

```gdscript
extends CharacterBody2D

const SPEED := 160.0
const SPEED_STEALTH := 80.0   # mode lampe faible
const DRAG := 0.82            # friction de l'eau

@onready var lamp := $PointLight2D
@onready var sprite := $Sprite2D

var lamp_mode := "normal"     # "normal" | "stealth" | "blue"

func _physics_process(delta: float) -> void:
    var input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    var speed := SPEED_STEALTH if lamp_mode == "stealth" else SPEED

    if input != Vector2.ZERO:
        velocity = velocity.lerp(input * speed, 0.12)
        sprite.flip_h = input.x < 0
    else:
        velocity *= DRAG

    move_and_slide()

func toggle_lamp_mode() -> void:
    match lamp_mode:
        "normal":
            lamp_mode = "stealth"
            lamp.energy = 0.3
            lamp.texture_scale = 0.8
        "stealth":
            lamp_mode = "normal"
            lamp.energy = 1.2
            lamp.texture_scale = 3.0

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("lamp_toggle"):
        toggle_lamp_mode()
    if event.is_action_pressed("tool_use"):
        ToolSystem.use_active_tool()
    if event.is_action_pressed("open_notebook"):
        get_tree().change_scene_to_file("res://scenes/ui/carnet.tscn")
```

**Paramètres d'entrée à créer** dans `Projet > Paramètres du projet > Contrôles` :
- `lamp_toggle` → F
- `tool_use` → E
- `open_notebook` → J
- `open_map` → M
- Les `ui_left/right/up/down` existent déjà, les assigner à ZQSD également

---

## Les zones — TileMapLayer

Chaque zone est une scène indépendante. Elle hérite d'une scène de base `zone_base.tscn` qui contient le CanvasModulate et les systèmes communs.

**Structure d'une zone**
```
Node2D  (zone_base.gd)
├── CanvasModulate
├── TileMapLayer        ← les tuiles (sol, murs, décors)
├── SpawnPoint          ← position d'entrée d'Ida
├── Exits/              ← zones de transition vers d'autres zones
│   ├── Area2D (exit_nord)
│   └── Area2D (exit_sud)
├── Creatures/          ← instances des créatures
├── Fragments/          ← objets narratifs interactifs
└── Ambiance            ← AudioStreamPlayer pour le son de fond
```

**Transition entre zones**

```gdscript
# Dans zone_base.gd
func _on_exit_nord_body_entered(body: Node) -> void:
    if body is CharacterBody2D:
        GameState.save_map_data()
        get_tree().change_scene_to_file("res://scenes/zones/zone_suivante.tscn")
```

`GameState.save_map_data()` sauvegarde l'état de la mini-map et la position avant la transition.

---

## La mini-map

C'est le deuxième système le plus important. Elle fonctionne avec un `SubViewport` qui capture une version simplifiée de la zone.

**Approche recommandée : dessin procédural sur un Canvas**

Pas de SubViewport — trop lourd. À la place, un `Control` nœud dans le HUD avec un script qui dessine via `_draw()`.

```gdscript
# minimap.gd
extends Control

var explored_cells := {}   # Dictionary { Vector2i : bool }
var ida_position := Vector2.ZERO

func reveal_cell(cell: Vector2i) -> void:
    if not explored_cells.has(cell):
        explored_cells[cell] = true
        queue_redraw()   # déclenche _draw()

func _draw() -> void:
    # Fond papier
    draw_rect(Rect2(Vector2.ZERO, size), Color("#f5f0e0"))
    
    # Cellules explorées
    for cell in explored_cells:
        var draw_pos := Vector2(cell) * 4.0   # 4px par cellule sur la mini-map
        draw_rect(Rect2(draw_pos, Vector2(3, 3)), Color("#1a1208"))
    
    # Position d'Ida
    var ida_map_pos := (ida_position / 16.0) * 4.0   # 16px = taille d'une tuile
    draw_circle(ida_map_pos, 3.0, Color("#f4a020"))
```

Ida appelle `minimap.reveal_cell()` chaque fois qu'elle entre dans une nouvelle tuile. La conversion position mondiale → cellule :

```gdscript
# Dans ida.gd, dans _physics_process
var current_cell := Vector2i(global_position / 16.0)
if current_cell != last_cell:
    last_cell = current_cell
    GameState.minimap.reveal_cell(current_cell)
```

**Style visuel** : les cellules révélées apparaissent avec un délai de 200ms (Tween sur l'alpha) pour simuler le dessin à la main. Ajouter un léger bruit sur la position de chaque trait pour l'aspect "croquis".

---

## L'oxygène

Autoload `GameState` ou composant dans le HUD. Simple et direct.

```gdscript
# dans game_state.gd
var oxygen_max := 480.0       # 8 minutes en secondes
var oxygen := oxygen_max
var is_diving := false

func _process(delta: float) -> void:
    if not is_diving:
        return
    var consumption := 1.0
    if PlayerRef.velocity.length() > 120:
        consumption = 1.4   # consommation accrue en fuite
    oxygen = max(0, oxygen - delta * consumption)
    
    if oxygen <= 0:
        force_surface()

func force_surface() -> void:
    # Retire le contrôle à Ida, la fait remonter automatiquement
    get_tree().change_scene_to_file("res://scenes/zones/surface.tscn")
```

**HUD O2** : une `ProgressBar` ou un dessin custom. Commence à pulser à 20%, teinte rouge les bords de l'écran à 10% (ColorRect en overlay avec alpha variable).

---

## Les créatures

### Sédentaires

Pas d'IA. `StaticBody2D` avec une `Area2D` de danger et un son en boucle. Si Ida entre dans la zone, dommage ou remontée forcée selon la créature.

```gdscript
# sedentaire.gd
extends StaticBody2D

@export var sound_loop : AudioStream
@onready var audio := $AudioStreamPlayer2D

func _ready() -> void:
    audio.stream = sound_loop
    audio.play()

func _on_danger_zone_body_entered(body: Node) -> void:
    if body.is_in_group("ida"):
        GameState.force_surface()
```

### Errants

`CharacterBody2D` avec navigation sur waypoints. Utiliser `NavigationAgent2D` ou, plus simple pour commencer, une liste de positions et un `Tween`.

```gdscript
# errant.gd
extends CharacterBody2D

@export var waypoints : Array[Vector2] = []
@export var speed := 60.0
var current_wp := 0

func _physics_process(delta: float) -> void:
    if waypoints.is_empty():
        return
    var target := waypoints[current_wp]
    var direction := (target - global_position).normalized()
    velocity = direction * speed
    move_and_slide()
    
    if global_position.distance_to(target) < 8.0:
        current_wp = (current_wp + 1) % waypoints.size()

func get_sound_volume_for_ida(ida_pos: Vector2) -> float:
    var dist := global_position.distance_to(ida_pos)
    return clamp(1.0 - dist / 300.0, 0.0, 1.0)
```

### Attirés

`CharacterBody2D` avec steering vers la lampe d'Ida si `lamp.energy > 0.5`.

```gdscript
# attire.gd
extends CharacterBody2D

var target : Node2D = null
const SPEED := 50.0
const DETECTION_RANGE := 200.0

func _physics_process(delta: float) -> void:
    if target == null:
        return
    var lamp = target.get_node("PointLight2D")
    if lamp.energy < 0.5:
        velocity *= 0.9   # décélère si lampe faible
        move_and_slide()
        return
    
    var direction := (target.global_position - global_position).normalized()
    velocity = velocity.lerp(direction * SPEED, 0.05)
    move_and_slide()
    
    if global_position.distance_to(target.global_position) < 20.0:
        GameState.force_surface()
```

---

## L'audio

**Principe** : pas de musique. Tout est `AudioStreamPlayer2D` (son spatial) ou `AudioStreamPlayer` (ambiance globale non directionnelle).

**AudioManager (autoload)**

```gdscript
# audio_manager.gd
extends Node

var zone_ambiance : AudioStreamPlayer

func play_zone_ambiance(stream: AudioStream, volume: float = 0.0) -> void:
    if zone_ambiance.stream == stream:
        return
    zone_ambiance.stream = stream
    zone_ambiance.volume_db = volume
    zone_ambiance.play()

func set_depth_filter(depth: float) -> void:
    # Plus on descend, plus les aigus disparaissent
    # Utiliser un AudioEffectLowPassFilter sur le bus Master
    var filter := AudioServer.get_bus_effect(0, 0) as AudioEffectLowPassFilter
    filter.cutoff_hz = lerp(8000.0, 400.0, depth / 50.0)
```

Configurer un bus audio `Master` avec un `AudioEffectLowPassFilter` dans `Projet > Paramètres audio`. C'est ce filtre que `set_depth_filter()` contrôle selon la profondeur d'Ida.

**Sons à générer** (via GDScript + AudioStreamGenerator, pas besoin de fichiers externes pour commencer) :
- Bruit blanc filtré = fond sous-marin de base
- Onde sinusoïdale 60Hz = pulsation des Errants
- Signal carré modulé = alerte des Attirés

```gdscript
# Exemple : générer un fond sous-marin procéduralement
func generate_underwater_ambiance() -> AudioStreamGenerator:
    var gen := AudioStreamGenerator.new()
    gen.mix_rate = 44100.0
    gen.buffer_length = 0.1
    return gen
```

---

## Le carnet d'Ida

Scène séparée qui s'ouvre en plein écran et met le jeu en pause (`get_tree().paused = true`).

Structure de chaque fragment dans `narrative.gd` :

```gdscript
# narrative.gd (autoload)

var fragments := {
    "frag_01": {
        "zone": "port_exterieur",
        "text": "SOLINE — maître de port adjoint, 1881-1887",
        "ida_comment": "Son nom. Sur une plaque officielle. Je ne m'y attendais pas.",
        "tone": "troubled",
        "found": false,
        "layer": 3
    },
    "frag_07": {
        "zone": "rues_commercantes",
        "text": "Registre de l'épicerie Aurel & Fils — semaine du 14 au 21 mars",
        "ida_comment": "Aurel. Le nom de famille de ma grand-mère avant le mariage. C'est ici.",
        "tone": "troubled",
        "found": false,
        "layer": 3
    },
}

func find_fragment(id: String) -> void:
    if fragments.has(id) and not fragments[id]["found"]:
        fragments[id]["found"] = true
        found_fragment.emit(fragments[id])

signal found_fragment(data: Dictionary)
```

---

## MVP — ordre d'implémentation

Aller dans cet ordre strict. Ne pas sauter d'étape.

**Étape 1 — Ida nage**
- Créer `ida.tscn` avec `CharacterBody2D`
- Implémenter le mouvement (lerp + drag)
- Scène de test avec un `TileMapLayer` simple (quelques tuiles de sol et de mur)
- Valider que les collisions fonctionnent

**Étape 2 — La vision**
- Ajouter `CanvasModulate` à la scène de test
- Ajouter `PointLight2D` à Ida
- Régler jusqu'à ce que ça ressemble à une lampe de plongée
- Implémenter le toggle mode faible (touche F)

**Étape 3 — L'oxygène**
- Ajouter `GameState` en autoload
- Implémenter le timer O2
- HUD minimal : une barre qui descend
- Tester la remontée forcée

**Étape 4 — La mini-map**
- Ajouter `Narrative` et `MiniMap` en autoload
- Implémenter `reveal_cell()` et `_draw()`
- Valider que la carte se remplit en naviguant

**Étape 5 — Premier Sédentaire**
- Créer `sedentaire.tscn`
- Le placer dans la scène de test
- Valider la détection et la remontée forcée au contact

**Étape 6 — Premier fragment narratif**
- Créer un objet interactif dans la scène
- Quand Ida s'approche (Area2D), afficher le texte
- Valider que le fragment s'enregistre dans `Narrative`

**Étape 7 — Port extérieur (première vraie zone)**
- Créer la scène `port_exterieur.tscn`
- TileMap de la zone (rester simple)
- Placer quelques Sédentaires inoffensifs
- Placer 2-3 fragments
- Valider la transition vers la surface

À ce stade : le jeu est jouable. Tout le reste (Errants, Attirés, outils avancés, zones profondes) s'ajoute sur cette base.

---

## Points d'attention Godot 4 spécifiques

- `move_and_slide()` n'a plus de paramètre de vélocité en Godot 4 — on assigne `velocity` avant d'appeler la fonction
- `$NomDuNoeud` est un raccourci pour `get_node("NomDuNoeud")` — préférer `@onready var x := $X` en haut du script
- Les signaux se connectent avec `.connect()` en code ou via l'interface "Nœud > Signaux" dans l'éditeur — les deux fonctionnent
- `@export var` permet d'éditer une variable directement dans l'inspecteur sans toucher le script — utiliser massivement pour les waypoints des Errants, les sons des zones, etc.
- Sauvegarder régulièrement les scènes (`Ctrl+S`) — Godot ne sauvegarde pas automatiquement

---

Première chose concrète à faire : créer `ida.tscn`, y ajouter un `CharacterBody2D`, un `CollisionShape2D` (capsule), un `ColorRect` temporaire comme sprite, et vérifier que le mouvement fonctionne dans une scène de test basique.
