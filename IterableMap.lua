local IterableMap = {}

function IterableMap.New()

	local indexByKey = {}
	local dataByKey = {}
	local indexMax = 0
	local unusedKey = 1
	local keyByIndex = {}
	local nextCounter = 0
	
	local api = {}

	function api.GetUnusedKey()
		while api.InMap(unusedKey) do
			unusedKey = unusedKey + 1
		end
		return unusedKey
	end
	
	function api.Add(key, data)
		if not key then
			return
		end
		if indexByKey[key] then
			-- Overwrites
			dataByKey[key] = data
			return
		end
		data = data or true
		indexMax = indexMax + 1
		keyByIndex[indexMax] = key
		dataByKey[key] = data
		indexByKey[key] = indexMax
	end
	
	function api.Remove(key)
		if (not key) or (not indexByKey[key]) then
			return false
		end
		local myIndex = indexByKey[key]
		local endKey = keyByIndex[indexMax]
		keyByIndex[myIndex] = endKey
		indexByKey[endKey] = myIndex
		keyByIndex[indexMax] = nil
		indexByKey[key] = nil
		dataByKey[key] = nil
		indexMax = indexMax - 1
		return true
	end
	
	function api.ReplaceKey(oldKey, newKey)
		if (not oldKey) or (not indexByKey[oldKey]) or indexByKey[newKey] then
			return false
		end
		keyByIndex[indexByKey[oldKey]] = newKey
		indexByKey[newKey] = indexByKey[oldKey]
		dataByKey[newKey] = dataByKey[oldKey]
		indexByKey[oldKey] = nil
		dataByKey[oldKey] = nil
		return true
	end
	
	-- Get is also set in the case of tables because tables pass by reference
	function api.Get(key)
		return dataByKey[key]
	end
	function api.Set(key, data)
		if not indexByKey[key] then
			api.Add(key, data)
		else
			dataByKey[key] = data
		end
	end
	
	function api.InMap(key)
		return (indexByKey[key] and true) or false
	end
	
	function api.Clear(key)
		indexByKey = {}
		dataByKey = {}
		indexMax = 0
		unusedKey = 1
		keyByIndex = {}
	end
	
	-- Use Next to implement iteration spread over many updates. Returns the next
	-- element using some internal counter.
	function api.Next()
		if indexMax < 1 then
			return false
		end
		nextCounter = nextCounter + 1
		if nextCounter > indexMax then
			nextCounter = 1
		end
		return keyByIndex[nextCounter], dataByKey[keyByIndex[nextCounter]]
	end
	
	-- To use Iterator, write "for unitID, data in interableMap.Iterator() do"
	-- This approach makes the garbage collector cry so try to use other methods
	-- of iteration.
	function api.Iterator()
		local i = 0
		return function ()
			i = i + 1
			if i <= indexMax then
				return keyByIndex[i], dataByKey[keyByIndex[i]]
			end
		end
	end
	
	-- Does the function to every element of the map. A less barbaric method
	-- of iteration. Recommended for cleanliness and speed.
	-- Using the third argument, index, is a little evil because index should
	-- be private.
	function api.Apply(funcToApply, ...)
		local i = 1
		while i <= indexMax do
			local key = keyByIndex[i]
			if funcToApply(key, dataByKey[key], i, ...) then
				-- Return true to remove element
				api.Remove(key)
			else
				i = i + 1
			end
		end
	end
	
	function api.ApplyNoArg(funcToApply)
		local i = 1
		while i <= indexMax do
			local key = keyByIndex[i]
			if funcToApply(key, dataByKey[key], i) then
				-- Return true to remove element
				api.Remove(key)
			else
				i = i + 1
			end
		end
	end
	
	-- This 'method' of iteration is for barbarians. Seems to have performance
	-- similar to Apply.
	function api.GetIndexMax()
		return indexMax
	end
	function api.IsEmpty()
		return (indexMax == 0)
	end
	function api.GetKeyByIndex(index)
		return keyByIndex[index]
	end
	function api.GetBarbarianData()
		return indexMax, keyByIndex, dataByKey
	end
	function api.GetDataByIndex(index)
		if keyByIndex[index] then
			return dataByKey[keyByIndex[index]]
		end
		return false
	end

	return api
end

return IterableMap
