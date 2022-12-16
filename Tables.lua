--[[
    Written By: Uwu/Darkdoom 12/5/2022
    Description: This class adds additional (linq-like) functionality to lua tables
    Notes: This is a work in progress
    --TODO: remove all the overloads and handle in single functions, totally forgot lua doesn't like that
]]

local table = require('table')

local Tables = {

}

local MetaTable = {
    __index = Tables,
}

function T(...)
    local arg = {...}
    local t = {}
    if(type(arg[1]) == 'table')then
        t = arg[1]
    else
        for i = 1, #arg do
            t[i] = arg[i]
        end
    end
    return setmetatable(t, MetaTable)
end

function Tables.Length(t)
    local count = 0
    for _ in t:It() do
        count = count + 1
    end
    return count
end

function Tables.DeepCopy(t)
    local copy = {}
    for k, v in pairs(t) do
        if type(v) == 'table' then
            v = Tables.DeepCopy(v)
        end
        copy[k] = v
    end
    return T(copy)
end

function Tables.ShallowCopy(t)
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = v
    end
    return T(copy)
end

function Tables.Clear(t)
    for k, v in pairs(t) do
        t[k] = nil
    end
end

function Tables.InsertAt(t, value, index)
    if(index == nil)then
        table.insert(t, value)
    else
        table.insert(t, index, value)
    end
end

function Tables.Insert(t, value)
    table.insert(t, value)
end

function Tables.RemoveAt(t, index)
    table.remove(t, index)
end

function Tables.Remove(t, value)
    for i, v in pairs(t) do
        if(v == value)then
            table.remove(t, i)
            return
        end
    end
end

function Tables.Contains(t, value)
    for v in t:It() do
        if(v == value)then
            return true
        end
    end
    return false
end

function Tables.Any(t, fn)
    for v in t:It() do
        if(fn(v))then
            return true
        end
    end
    return false
end

function Tables.All(t, fn)
    for v in t:It() do
        if(not fn(v))then
            return false
        end
    end
    return true
end

function Tables.Append(t, val)
    if(type(val) == 'table')then
        for v in val:It() do
            table.insert(t, v)
        end
    else
        table.insert(t, val)
    end
end

function Tables.Average(t)
    local sum = 0
    for v in t:It() do
        sum = sum + v
    end
    return sum / Tables.Length(t)
end

function Tables.Chunk(t, maxChunkSize)
    local chunks = T()
    local chunk = T()
    for i, v in pairs(t) do
        if(i % maxChunkSize == 0)then
            chunks:Insert(chunk)
            chunk = T()
        else
            chunk:Insert(v)
        end
    end
    if(chunk:Length() > 0)then
        chunks:Insert(chunk)
    end
    return chunks
end

function Tables.Concat(t1, t2)
    local new = T()
    for v in t1:It() do
        new:Insert(v)
    end
    for v in t2:It() do
        new:Insert(v)
    end
    return new
end

function Tables.Count(t, fn)
    local count = 0
    for v in t:It() do
        if(fn(v))then
            count = count + 1
        end
    end
    return count
end

function Tables.Distinct(t)
    local new = T()
    for v in t:It() do
        if(not new:Contains(v))then
            new:Insert(v)
        end
    end
    return new
end

function Tables.Distinct(t, fnComparison)
    local new = T()
    for v in t:It() do
        if(not new:Any(function(x) return fnComparison(x, v) end))then
            new:Insert(v)
        end
    end
    return new
end

function Tables.ElementAt(t, index)
    return t[index]
end

function Tables.Empty(t)
    return Tables.Length(t) == 0
end

function Tables.First(t)
    return t[1]
end

function Tables.FirstBy(t, fn)
    for v in t:It() do
        if(fn(v))then
            return v
        end
    end
end

function Tables.FirstOrDefault(t)
    if(Tables.Length(t) > 0)then
        return Tables.First(t)
    end
    return nil
end

function Tables.FirstOrDefaultBy(t, fn)
    if(Tables.Length(t) > 0)then
        return Tables.First(t, fn)
    end
    return nil
end

function Tables.ForEach(t, fn)
    for v in t:It() do
        fn(v)
    end
end

function Tables.It(t)
    local i = 0
    return function()
        i = i + 1
        return t[i]
    end
end

function Tables.GroupBy(t, fn)
    local groups = T()
    for v in t:It() do
        local key = fn(v)
        if(not groups:ContainsKey(key))then
            groups[key] = T()
        end
        groups[key]:Insert(v)
    end
    return groups
end

function Tables.Join(t1, t2, fnJoin)
    local new = T()
    for v in t1:It() do
        for v2 in t2:It() do
            if(fnJoin(v, v2))then
                new:Insert(v)
            end
        end
    end
    return new
end

function Tables.Last(t)
    return t[Tables.Length(t)]
end

function Tables.LastOrDefault(t)
    if(Tables.Length(t) > 0)then
        return Tables.Last(t)
    end
    return nil
end

function Tables.LastOrDefault(t, fn)
    if(Tables.Length(t) > 0)then
        return Tables.Last(t, fn)
    end
    return nil
end

function Tables.Max(t)
    local max = t[1]
    for v in t:It() do
        if(v > max)then
            max = v
        end
    end
    return max
end

function Tables.Max(t, fn)
    local max = t[1]
    for v in t:It() do
        if(fn(v) > fn(max))then
            max = v
        end
    end
    return max
end

function Tables.Min(t)
    local min = t[1]
    for v in t:It() do
        if(v < min)then
            min = v
        end
    end
    return min
end

function Tables.Min(t, fn)
    local min = t[1]
    for v in t:It() do
        if(fn(v) < fn(min))then
            min = v
        end
    end
    return min
end

function Tables.OrderBy(t, fn)
    local new = T()
    for v in t:It() do
        new:Insert(v)
    end
    table.sort(new, fn)
    return new
end

function Tables.OrderByDescending(t, fn)
    local new = T()
    for v in t:It() do
        new:Insert(v)
    end
    table.sort(new, function(a, b) return fn(b, a) end)
    return new
end

function Tables.Prepend(t, v)
    local new = T()
    new:Insert(v)
    for v in t:It() do
        new:Insert(v)
    end
    return new
end

function Tables.PrependRange(t1, t2)
    local new = T()
    for v in t2:It() do
        new:Insert(v)
    end
    for v in t1:It() do
        new:Insert(v)
    end
    return new
end

function Tables.Reverse(t)
    local new = T()
    for i = Tables.Length(t), 1, -1 do
        new:Insert(t[i])
    end
    return new
end

function Tables.Select(t, fn)
    local new = T()
    for v in t:It() do
        new:Insert(fn(v))
    end
    return new
end

function Tables.SequenceEqual(t1, t2)
    if(Tables.Length(t1) ~= Tables.Length(t2))then
        return false
    end
    for i = 1, Tables.Length(t1) do
        if(t1[i] ~= t2[i])then
            return false
        end
    end
    return true
end

function Tables.Skip(t, n)
    local new = T()
    for i = n + 1, Tables.Length(t) do
        new:Insert(t[i])
    end
    return new
end

function Tables.SkipWhile(t, fn)
    local new = T()
    local i = 1
    while(fn(t[i]))do
        i = i + 1
    end
    for i = i, Tables.Length(t) do
        new:Insert(t[i])
    end
    return new
end

function Tables.Sum(t)
    local sum = 0
    for v in t:It() do
        sum = sum + v
    end
    return sum
end

function Tables.Take(t, n)
    local new = T()
    for i = 1, n do
        new:Insert(t[i])
    end
    return new
end

function Tables.TakeWhile(t, fn)
    local new = T()
    for v in t:It() do
        if(fn(v))then
            new:Insert(v)
        else
            break
        end
    end
    return new
end

function Tables.ToLookup(t, fn)
    local new = T()
    for v in t:It() do
        local key = fn(v)
        if(not new[key])then
            new[key] = T()
        end
        new[key]:Insert(v)
    end
    return new
end

function Tables.Where(t, fn)
    local new = T()
    for v in t:It() do
        if(fn(v))then
            new:Insert(v)
        end
    end
    return new
end

return Tables