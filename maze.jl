using Gen
##
goal = [5,5]
function get_map() :: Matrix{Int64}
        return copy(
        [0 0 0 0 0
         1 1 0 1 1
         0 1 0 0 0
         0 0 1 1 0
         0 0 0 1 0])
end
function move!(position, trace_map)
    map = get_map()
    fail = [1, 1, 10]
    if position[1:2] == goal
        #println("In goal")
        return position
    end
    if position[1:2] == fail[1:2] && position[3] > 0
        #println("In fail")
        position[3] -= 1
        return position 
    end
    d = trace_map[(position[1], position[2])][1] ? 1 : 2
    f = trace_map[(position[1], position[2])][2] ? 1 : 2
    position[d] = position[d] + f
    if position[d] > 5
        position[d] = 5
    elseif position[d] < 1
        position[d] = 1
    end
    if map[position[1], position[2]] != 0
        position = fail
    end
    return position
end
function resolve(position, dir_map)
    pos = [1,1,0]
    pos_set = Set()
    while !in(pos, pos_set)
        pos = move!(pos, 
                dir_map
            )
        push!(pos_set, pos)
    end
    return pos
end
@gen function model()
    position = [1, 1, 0]
    maze = get_map()
    dir_maze = Dict()
    for index_x in 1:size(maze, 1)
        for index_y in 1:size(maze, 2)
                dir_maze[(index_x, index_y)] = (@trace(bernoulli(0.5), (index_x, index_y, :dir)), 
                @trace(bernoulli(0.5), (index_x, index_y, :forward)),
                @trace(bernoulli(0.5), (index_x, index_y, :fail)))
        end
    end
    position = resolve(position, dir_maze)
    @trace(normal(position[1], 0.01), :x)
    @trace(normal(position[2], 0.01), :y)
    return position
end


function do_inference(x, y, num_iters)
    trace, = generate(model, (), choicemap((:x, x), (:y, y)))
    trace0 = trace
    for i=1:num_iters
        trace, = mh(trace, complement(select(:y, :x)))
    end
    return trace0, trace
end

start, conclusion = do_inference(goal[1], goal[2], 100000)
print()
println(get_score(start))
println(get_score(conclusion))

function draw(trace)
    dir_map = get_map()
    directions = Dict()
    for x in 1:size(dir_map, 1)
        for y in 1:size(dir_map, 2)
            directions[x, y] = (
                get_value(trace, (x, y, :dir)),
                get_value(trace, (x, y, :forward)),
                get_value(trace, (x, y, :fail)),
                )
        end
    end
    pos = [1,1,0]
    i = 1
    traced_map::Matrix{Int64} = get_map() * -1
    pos_set = Set()
    while !in(pos, pos_set)
        traced_map[pos[1], pos[2]] = i
        pos = move!(pos, 
                directions
            )
        push!(pos_set, pos)
        println("Got back ", pos)
        i = i + 1
    end
    traced_map[pos[1], pos[2]] = 99
    display(traced_map)
    return directions
end
draw(get_choices(conclusion))