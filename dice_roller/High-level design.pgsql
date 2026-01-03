┌─────────────────────────────────────────────┐
│                User / UI                    │
│  (CLI, Phoenix, LiveView, Mobile, etc.)     │
└─────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────┐
│          Daggerheart.TableServer             │
│              (GenServer)                    │
│                                             │
│  - holds Table state                         │
│  - serializes access                         │
│  - exposes public API                        │
│                                             │
│  API:                                       │
│   register_player                            │
│   start_check                                │
│   roll_for_player                            │
│   get_pools / get_history / get_check        │
└─────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────┐
│              Daggerheart.Table               │
│           (PURE domain logic)                │
│                                             │
│  - players map                               │
│  - hope/fear pools                           │
│  - checks map                                │
│  - history                                  │
│                                             │
│  Functions:                                 │
│   new                                       │
│   put_player                                │
│   put_check                                 │
│   apply_result                              │
│   record_player_roll                        │
└─────────────────────────────────────────────┘
                     │
        ┌────────────┴─────────────┐
        ▼                          ▼
┌──────────────────────┐   ┌──────────────────────┐
│  Daggerheart.Player  │   │   Daggerheart.Check   │
│     (STRUCT)         │   │      (STRUCT)         │
│                      │   │                      │
│  id                  │   │  id                  │
│  name                │   │  trait               │
│  traits map          │   │  difficulty           │
│                      │   │  advantage/disadv     │
│  Functions:          │   │  status               │
│   new                │   │  rolls map            │
│   trait_mod          │   │                      │
│                      │   │  Functions:           │
│                      │   │   new                 │
│                      │   │   put_roll            │
│                      │   │   close               │
└──────────────────────┘   └──────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────┐
│           Daggerheart.Duality                │
│        (PURE rules engine)                   │
│                                             │
│  - Hope/Fear dice logic                      │
│  - success vs difficulty                    │
│  - critical detection                       │
│  - hope/fear deltas                         │
│                                             │
│  Function:                                  │
│   roll_action                               │
└─────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────┐
│               DiceRoller                    │
│           (pure RNG utilities)               │
│                                             │
│  roll/1                                     │
│  roll_many/2                                │
│  roll_d/1                                   │
└─────────────────────────────────────────────┘
