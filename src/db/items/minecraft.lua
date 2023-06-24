minecraft = {
    piston = {
        crafting = {
            { 'plank',       'plank',      'plank'       },
            { 'cobblestone', 'iron_ingot', 'cobblestone' },
            { 'cobblestone', 'redstone',   'cobblestone' },
        }
    },
    crafting_table = {
        crafting = {
            { 'plank', 'plank' },
            { 'plank', 'plank' },
        }
    },
    torch = {
        crafting = {
            { 'coal'  }.
            { 'stick' },
        }
    },
    diamond_pickaxe = {
        crafting = {
            { 'diamond', 'diamond', 'diamond' },
            { '',        'stick',   ''        },
            { '',        'stick',   ''        },
        }
    },
    diamond_shovel = {
        crafting = {
            { 'diamond' },
            { 'stick'   },
            { 'stick'   },
        }
    },
    diamond_hoe = {
        crafting = {
            { 'diamond', 'diamond' },
            { '',        'stick'   },
            { '',        'stick'   },
        }
    },
    diamond_axe = {
        crafting = {
            { 'diamond', 'diamond' },
            { 'diamond', 'stick'   },
            { '',        'stick'   },
        }
    },
    chest = {
        purpose = 'storage',
        slots = { n=27, capacity='stack' },
        crafting = {
            { 'plank', 'plank', 'plank' },
            { 'plank', '',      'plank' },
            { 'plank', 'plank', 'plank' },
        }
    },
    barrel = {
        purpose = 'storage',
        slots = { n=27, capacity='stack' },
        crafting = {
            { kind='craft', recipe={
                { 'plank', 'wood_slab', 'plank' },
                { 'plank', '',          'plank' },
                { 'plank', 'wood_slab', 'plank' },
            }}
        }
    },
    furnace = {
        purpose = 'smelting',
        energy_units = 'items_processed',
        slots = {
            'input',
            'fuel',
            'output',
        },
        fuel = {
            coal       = 8,
            coal_block = 80,
            wood_slab  = 0.75,
            plank      = 1.5,
            log        = 1.5,
        },
        crafting = {
            { kind='craft', recipe = {
                { 'cobblestone', 'cobblestone', 'cobblestone' },
                { 'cobblestone', '',            'cobblestone' },
                { 'cobblestone', 'cobblestone', 'cobblestone' },
            }}
        }
    },
    diamond_ore = {
        drops = 'diamond'
    },
    diamond = {
        source = {
            { kind='mining', depth='deep', rarity='rare' }
        }
    },
    iron_ore = {
        source = {
            { kind='mining', depth='any', rarity='common' }
        }
    },
    iron_ingot = {
        crafting = {
            { kind='smelting', source='iron_ore', yield=1 },
        }
    },
    stone = {

    },
    cobblestone = {
    },
    glass = {
        crafting = {
            { kind='smelting', source='sand', yield=1 },
        }
    },
    sand = {
        source = {
            { kind='mining', depth='surface' }
        }
    },



diamond:
  tags: [resource]
  source:
    - mining:
        depth: deep
        rarity: rare
        vein: [1,16]


iron_ingot:
  tags: [resource, metal]
  source:
    - smelt: iron_ore
    - smelt: iron_powder
    - cast: iron_ore
      yield: 2

iron_ore:
  tags: [resource, block, ore]
  source: mining

iron_powder:
  tags: [powder, metal]
  crafting:
    grind: iron_ore
    yield: 2

glass:
  crafting:
    smelt: sand

redstone:
  tags: [resource, placeable]
  source:
    - mining


cobblestone:
  tags: [resource, block]
  source:
    - mining

plank:
  tags: [block, building]
  crafting:
    recipe:
      - [log]
    yield: 4

stick:
  tags: [item]
  crafting:
    recipe:
      - [plank]
      - [plank]
    yield: 4

log:
  tags: [resource, building]
  source: tree_farm

cobble:
  tags: [resource, building]
  source:
    - cobble_generation
    - mining

coal_ore:
  tags: [resource, block]
  drops:
    coal:4: 1

redstone_ore:
  tags: [resource, block]
  drops:
    redstone: 5

lapis_ore:
  tags: [resource, block]
  drops:
    dye,4: 9

dye,4:
  alias: lapis_luzli
  tags: [dye]


diamond_ore:
  tags: [resource, block]
  drops:
    diamond: 1

gravel:
  drops:
    gravel: 1
    flint:  1



coal:
  tags: [resource, combustible]
  groupings: [any_coal]
  source:
    - mining

charcoal:
  tags: [item, combustible]
  groupings: [any_coal]
  crafting:
    smelt: log
    yield: 1








}
