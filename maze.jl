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
function move!(position, forward, dir, does_fail)
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
    d = dir ? 1 : 2
    f = forward ? 1 : -1
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
@gen function model()
    position = [1, 1, 0]
    for index in 1:8
        position = move!(position,
            @trace(bernoulli(0.5), (index, :dir)), 
            @trace(bernoulli(0.5), (index, :forward)),
            @trace(bernoulli(0.5), (index, :fail))
        )
    end
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
    pos = [1,1,0]
    i = 1
    traced_map::Matrix{Int64} = get_map() * -1
    while has_value(trace, (i, :dir))
        traced_map[pos[1], pos[2]] = i
        pos = move!(pos, 
            get_value(trace, (i, :dir)),
            get_value(trace, (i, :forward)),
            get_value(trace, (i, :fail))
            )
        println("Got back ", pos)
        i = i + 1
    end
    traced_map[pos[1], pos[2]] = 99
    display(traced_map)
end
draw(get_choices(conclusion))