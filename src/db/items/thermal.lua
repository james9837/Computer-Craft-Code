
local thermal = {
    machine_pulverizer = {
        purpose      = grinding,
        energy_units = 'rf',
        is_block     = true,
        slots = {
            'input',
            'extra',
            'output',
            'output',
            'output',
            'output',
        },
        energy_usage = {
            ingot  = 2000,
            ore    = 4000,
            cobble = 4000,
            gravel = 4000,
        },
        crafting = {
            { '',            'piston',        ''            },
            { 'flint',       'machine_frame', 'flint'       },
            { 'copper_gear', 'rf_coil',       'copper_gear' },
        },
    },
    dynamo_stirling = {
        purpose      = generator,
        energy_units = 'rf',
        is_block     = true,
        slots = {
            'fuel'
        },
        fuel = {
            sapling    =   1000,
            block_wood =   3000,
            coal       =  24000,
            coal_block = 240000,
        },
        crafting = {
            { '',           'rf_coil',    ''          },
            { 'iron_ingot', 'iron_gear', 'iron_ingot' },
            { 'stone',      'redstone',  'stone'      },
        },
    },
    redstone_furnace = {
        purpose      = smelting,
        energy_units = 'rf',
        energy_usage = 2000,
        is_block     = true,
        slots = {
            'input',
            'output',
        },
        crafting = {
            { '',            'redstone',      ''            },
            { 'bricks',      'machine_frame', 'bricks'      },
            { 'copper_gear', 'rf_coil',       'copper_gear' },
        }
    },
    machine_frame = {
        is_block = true,
        crafting = {
            { 'iron_ingot', 'glass',    'iron_ingot' },
            { 'glass',      'tin_gear', 'glass',     },
            { 'iron_ingot', 'glass',    'iron_ingot' },
        }
    },
    tin_gear = {
        crafting = {
            { '',          'tin_ingot',   ''          },
            { 'tin_ingot', 'iron_nugget', 'tin_ingot' },
            { '',          'tin_ingot',   ''          },
        }
    },
    copper_gear = {
        crafting = {
            { '',             'copper_ingot', ''             },
            { 'copper_ingot', 'iron_nugget',  'copper_ingot' },
            { '',             'copper_ingot', ''             },
        }
    },
    rf_coil = {
        crafting = {
            { '',         '',           'redstone' },
            { '',         'gold_ingot', ''         },
            { 'redstine', '',           ''         },
        }
    },
}

return {thermal = thermal}
