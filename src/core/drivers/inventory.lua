{
        data = {
        },
        get_state = function()
        end,
        set_state = function()
        end,
        empty_slot = function()
            for slot=1,16,1 do
                local count = turtle.getItemCount(slot)
                if count == 0 then
                    return slot
                end
            end
            return nil
        end,
        drop_all = function()
            for i=1,16,1 do
                if turtle.getItemCount(i) > 0 then
                    if bot.inventory.drop(i) == false then
                        return false
                    end
                end
            end
            return true
        end,
        drop = function(slot)
            slot = slot or 1
            turtle.select(slot)
            return turtle.drop()
        end,
        get_slot_detail = function(slot)
            return turtle.getItemDetail(slot)
        end,
        drop_select = function(names_to_drop)
            local _n = 'bot.inventory.make_room'
            if names_to_drop == nil then
                log.error(_n, 'no items in list to drop')
            end
            -- drop all items with names matching entries in the list
            log.trace(_n, 'scanning inventory for garbage..')
            for slot=1,16,1 do
                local detail = turtle.getItemDetail(slot)
                if detail ~= nil then
                    if names_to_drop[detail.name] ~= nil then
                        log.debug(_n, 'dropping:'..detail.name..' #'..tostring(detail.count))
                        turtle.select(slot)
                        turtle.drop(detail.count)
                    end
                end
            end
        end,
        condense = function()
            local _n = 'bot.inventory.condense'
            local free_spaces = {}
            local spaces_cleared = 0
            for slot=1,16,1 do
                local detail = turtle.getItemDetail(slot)
                if detail ~= nil then
                    local free = turtle.getItemSpace(slot)
                    local key = detail.name..tostring(detail.damage)

                    if free_spaces[key] == nil then
                        if free > 0 then
                            free_spaces[key] = {{slot=slot, free=free}}
                        end
                    else
                        for i, d in ipairs(free_spaces[key]) do
                            turtle.select(slot)
                            turtle.transferTo(d.slot)
                            if turtle.getItemSpace(d.slot) == 0 then
                                free_spaces[key][i] = nil
                            end
                            local count = turtle.getItemCount(slot)
                            if count == 0 then
                                spaces_cleared = spaces_cleared + 1
                                break
                            end
                        end
                        -- re-check free space for the item we just handed..
                        local count = turtle.getItemCount(slot)
                        local free = turtle.getItemSpace(slot)
                        if count > 0 then
                            table.insert(free_spaces[key], {slot=slot, free=free})
                        end
                    end
                end
            end
            log.debug(_n, 'cleared '..tostring(spaces_cleared)..' spaces')
        end,
        can_hold_block_item = function(block, meta)
            local _n = 'bot.inventory.can_hold_block_item'
            -- allow call with table for block::
            --   {name="some:name", meta=5}
            -- or call with separate arguments
            --
            if block == nil then
                log.debug(_n, 'called with no block')
                return nil
            end

            if block.metadata == nil and meta == nil then
                log.debug(_n, 'called with no meta')
                return nil
            end

            -- setup the default search - can the block itself fit in inventory?
            local items_to_fit = {
                name = block.name     or block,
                d    = block.metadata or meta,
                n  = 1,
            }

            -- grab the drop definition from our database...
            local data = block_items[items_to_fit.name]

            -- not found in database, so just check if bot can hold the
            -- block itself
            if data == nil then
                log.debug(_n, 'can hold the block? -> '..items_to_fit.name)
                return bot.inventory.can_hold_items({items_to_fit})
            end

            -- block is found in database (it doesn't drop itself)
            -- check if what it drops can be held..
            local detail = data[items_to_fit.d]
            if detail == nil then
                return bot.inventory.can_hold_items({items_to_fit})
            end

            if detail.kind == nil then
                return bot.inventory.can_hold_items({detail})
            end

            return bot.inventory.can_hold_items(detail, detail.n)
        end,
        can_hold_items = function(items, n_item_types)
            print('can hold items:'..tostring(items)..','..tostring(n_item_types))
            print('..'..tostring(items[1])..','..tostring(items[2]))
            n_item_types = n_item_types or 1

            if n_item_types == 0 then
                return true
            end

            local items_to_find = {}
            for i=1, n_item_types, 1 do
                local _item = items[i]
                items_to_find[_item.name] = { d=_item.d, qty=_item.n}
            end

            local spaces_found = 0
            local item_types_fitting = 0
            for slot=16,1,-1 do
                local detail = turtle.getItemDetail(slot)
                if detail == nil then
                    spaces_found = spaces_found + 1
                    if spaces_found == n_item_types then
                        return true
                    end
                else
                    local _item = items_to_find[detail.name]
                    if _item ~= nil then
                        if _item.d == detail.damage then
                            local space_in_slot = turtle.getItemSpace(slot)
                            if space_in_slot >= _item.qty then
                                items_to_find[detail.name] = nil
                                item_types_fitting = item_types_fitting + 1
                                if item_types_fitting == n_item_types then
                                    return true
                                end
                            else
                                _item.qty = _item.qty -  space_in_slot
                            end
                        end
                    end
                end
            end

            return false
        end
    }
