# TowerHell — Game Design Spec
**Date:** 2026-05-03  
**Engine:** Godot 4.6 (GDScript)  
**Genre:** Tower Defense + Roguelite + Idle RPG

---

## 1. Concept

Il giocatore interpreta un mago oscuro che difende la sua torre dall'assalto di ondate infinite di umani. Controlla un mago che si muove lungo un cerchio attorno alla torre, punta liberamente le magie con un cursore (aim-star), evoca truppe e modifica il terreno. Il gioco finisce quando il cerchio magico (HP del player) si esaurisce.

**Pillars:**
- **Orchestrazione** — il piacere di dirigere il caos con magie e truppe
- **Build diversity** — ogni run evolve diversamente grazie ai perk elementali casuali
- **Progressione soddisfacente** — ogni morte lascia qualcosa di permanente

---

## 2. Prospettiva e Platform

- **Vista:** 3/4 view (~65°) — torre visibile in altezza, cerchi leggibili
- **Platform:** Cross-platform (PC-first, porting mobile successivo)
  - PC: mouse per aim-star, A/D o frecce per muovere il mago, Q/W/E/R per elementi
  - Mobile: joystick SX per movimento, joystick DX per aim-star, 4 tasti elemento

---

## 3. Core Game Loop

```
LOOP SINGOLA RUN
│
├── Spawn nemici dai bordi mappa (tutte le direzioni)
├── Mago mira con aim-star → cast magia elemento (Q/W/E/R)
├── Truppe evocate all'aim-star → auto-aggro area
├── Kill → drop Anime (upgrade immediato) + Oro (spendibile in-run)
├── EXP da kill → Level Up → scegli 1 perk tra 3 casuali per elemento
├── Ogni 60s: intensità ondate scala
├── Ogni 3 min: "Corrupted Night" 30s (spawn x3, drop x2)
├── Ogni 10 livelli mago: mini-boss con HP bar
├── HP cerchio magico → 0: MORTE
│
└── FINE RUN
    ├── Oro accumulato → meta-shop (Grimorio)
    └── Nuova run: perk resettati, meta-upgrade persistono
```

---

## 4. Wizard Mechanics

### Movimento
- Il mago si muove **solo lungo il cerchio azzurro** (raggio fisso dalla torre)
- Velocità costante, nessuna accelerazione
- La sprite ruota sempre verso la direzione dell'aim-star

### Aim-Star
- Cursore magico libero su tutta la mappa
- Raggio minimo: appena fuori dal cerchio rosso (non può mirare dentro la torre)
- Nessun auto-lock — skill del giocatore nel posizionarlo

---

## 5. Sistema Magie — 4 Elementi

| Elemento | Tasto PC | Cast base | Effetto status | Upgrade notevole |
|----------|----------|-----------|---------------|-----------------|
| **Fuoco** 🔥 | Q | Fireball AoE sull'aim-star | Burning DoT 3s | Pioggia meteoriti nell'area |
| **Ghiaccio** ❄️ | W | Blizzard a cono dalla posizione mago | Slow 50%, Freeze a stack | Muro di ghiaccio (terrain block) |
| **Terra** 🪨 | E | Picchi di pietra sull'aim-star | Stun breve + ostacolo fisico | Fossato / muro permanente |
| **Arcana** 💜 | R | Bolt rimbalzante tra nemici | DoT 5s + bonus anime al kill | Campo Arcano DoT persistente |

### Combo Elementali
Si attivano automaticamente quando due spell colpiscono la stessa area entro 1 secondo:

| Combo | Risultato |
|-------|-----------|
| Fuoco + Ghiaccio | **Vapore** — nube che acceca/disorienta i nemici |
| Terra + Fuoco | **Magma** — fiume di lava che rallenta e brucia |
| Ghiaccio + Arcana | **Cristallo Arcano** — nemici frozen subiscono danno Arcano x3 |

### Soul Infuse
Tenere premuto il tasto elemento dopo il cast spende Anime per potenziare il proiettile appena lanciato (danno +%, area +%, durata status +%).

---

## 6. Economy

### In-Run
| Risorsa | Fonte | Uso |
|---------|-------|-----|
| **Anime** 💜 | Ogni kill (1 base, boss 10+) | Soul Infuse, moltiplicatore combo stesso elemento |
| **Oro** 🟡 | Ogni 5-8 kill, garantito da mini-boss | Circle Menu in-run: evoca truppe, ripara cerchio, piazza postazioni |
| **EXP** | Ogni kill | Level up → perk casuale da elemento |

### Meta (tra run)
- Oro accumulato → speso nel Grimorio (meta-shop)
- Sblocca: nuove spell base, nuove truppe, upgrade HP cerchio magico
- Perk run-specifici si resettano; unlock Grimorio sono permanenti

---

## 7. Wave System

```
SPAWN LOGIC
├── Spawn da bordi mappa in tutte le direzioni
├── Peso spawn aumentato dove il mago NON sta guardando
├── Ogni 60s → +10% spawn rate, +5% velocità nemici
├── Ogni 3 min → "Corrupted Night" 30s: spawn x3, drop anime x2
└── Ogni 10 level mago → mini-boss (HP bar visibile, drop Oro garantito)

TIPI NEMICI (con sprite disponibili)
├── Orc — melee pesante, lento, molto HP
└── Soldier — ranged, spara Arrow, mantiene distanza
```

---

## 8. Truppe & Terrain

### Truppe (costo Oro, evocate all'aim-star)
| Truppa | Comportamento | Unlock |
|--------|--------------|--------|
| Orc alleato | Melee, si posiziona all'aim-star, aggro area automatico | Base |
| Arciere | Ranged fisso, attacca nel suo raggio | Meta |
| Golem di Terra | Tank lento, blocca fisicamente il passaggio | Meta |

### Terrain Modification (spell Terra avanzate)
| Struttura | Effetto | Durata |
|-----------|---------|--------|
| Muro di Pietra | Ostacolo fisico, devia pathfinding nemici | Permanente (run) |
| Fossato Arcano | Slow -80% al traversamento | Permanente (run) |
| Pilastro di Ghiaccio | Blocca + danno periodico | 30s |

---

## 9. Assegnazione Sprite

| File | Ruolo |
|------|-------|
| `Orc-Idle/Walk/Attack/Death/Hurt` | Nemico melee + Orc alleato (palette swap) |
| `Soldier-Idle/Walk/Attack1-3/Death` | Nemico ranged |
| `Arrow01` | Proiettile Soldier + Arciere alleato |
| `Explosion_two_colors` (10f) | Impatto Fuoco / meteorite |
| `Circle_explosion` (10f) | Impatto generico / shattering Ghiaccio |
| `Explosion_gas_circle` (10f) | Campo Arcano / DoT zone |
| `background.png` | Base mappa |
| `Action_panel` | HUD basso: 4 tasti elemento + cooldown |
| `Circle_menu` | Menu radiale spesa Oro (hold) |
| `Shop` | Meta-shop / Grimorio |
| `Inventory` + `Equipment` | Gestione perk attivi |
| `Win_loose` | Schermata fine run |
| `Icons` (×11) | Elementi, anime, oro, HP |
| `Decorative_cracks` | Overlay cerchio magico danneggiato |
| `Numbers` + `Numbers_levels` | Danno floating, livello |
| `Buttons` + `Main_menu` | UI menu principale |

### Sprite da creare/trovare
- Mago player (pixel art 3/4 view, 4 direzioni, idle/walk/cast)
- Torre centrale (hexagram dark fantasy, 3/4 view)
- Cerchio magico (integro + stati crack progressivi)
- VFX ghiaccio (Ice spike, blizzard cone)
- VFX terra (stone spike, wall rising)

---

## 10. Architettura Tecnica (Godot 4)

**Pattern:** Scene-per-entity (allineato a quiver-dev/tower-defense-godot4)

```
res://
├── scenes/
│   ├── main/          # Main.tscn (game manager)
│   ├── world/         # Arena.tscn (mappa + cerchi)
│   ├── player/        # Wizard.tscn
│   ├── tower/         # Tower.tscn + MagicCircle.tscn
│   ├── enemies/       # Orc.tscn, Soldier.tscn, Boss.tscn
│   ├── troops/        # OrcAlly.tscn, Archer.tscn, Golem.tscn
│   ├── spells/        # Fireball.tscn, Blizzard.tscn, StonePike.tscn, ArcaneBolt.tscn
│   ├── terrain/       # StoneWall.tscn, ArcaneMoat.tscn
│   └── ui/            # HUD.tscn, CircleMenu.tscn, MetaShop.tscn, RunEnd.tscn
├── scripts/           # Autoloads: GameManager, WaveManager, EconomyManager
├── resources/         # SpellData.tres, EnemyData.tres (dati bilanciamento)
└── sprites/           # (assets esistenti + nuovi)
```

**Autoloads (Singleton):**
- `GameManager` — stato run, HP cerchio, livello mago
- `WaveManager` — spawn logic, Corrupted Night timer
- `EconomyManager` — anime, oro, meta-valuta
- `SignalBus` — eventi globali (enemy_died, spell_cast, level_up)

**Riferimento:** `quiver-dev/tower-defense-godot4` per pattern pathfinding (NavigationServer2D) e FSM nemici.

---

## 11. Repo GitHub

- **Nome:** `TowerHell`
- **Branch strategy:** `main` (stabile) + `dev` (sviluppo) + feature branch per sistema
- **Tracking:** Issues GitHub per ogni milestone, Projects board per workflow
