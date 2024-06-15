function is_hitting(queen_positions::Array{Int64, 1}, q::Int64)
    if q == 1
        return false
    end
    for i in 1:q-1
        if queen_positions[i] == queen_positions[q] || abs(queen_positions[i] - queen_positions[q]) == abs(i - q)
            return true
        end
    end
    return false
end

function move!(queen_positions::Array{Int64, 1}, q::Int64, N::Int64)
    if queen_positions[q] == N
        queen_positions[q] = 1
        return true
    else
        queen_positions[q] += 1
        return false
    end
end

function mirror_and_check(x::Array{Int64, 1}, y::Array{Int64, 1}, N::Int64)
    (x == y) || (((N+1) .- x) == y) || (reverse(x) == y) || ((N+1) .- reverse(x) == y)
end
function rot90(x::Array{Int64, 1}, N::Int64)
    y = fill(0, N)
    for (i, x) in enumerate(x)
        y[x] = i
    end
    return y
end
function is_fundamental(new_ans::Array{Int64, 1}, answers::Array{Array{Int64, 1}, 1}, N::Int64)
    if length(answers) == 0
        return true
    end
    for ans in answers
        if mirror_and_check(new_ans, ans, N)
            return false
        end
        new_ans_rot = rot90(new_ans, N)
        if mirror_and_check(new_ans_rot, ans, N)
            return false
        end
    end
    return true
end


function solve_nqueen(N::Int64)
    queen_positions = fill(1, N)
    answers = []
    answers_fundamental = Array{Array{Int64, 1}, 1}([])
    q = 1
    end_flag = false
    while true
        while is_hitting(queen_positions, q)
            while move!(queen_positions, q, N)
                q -= 1
                if q == 0
                    end_flag = true
                    break
                end
            end
        end
        if end_flag
            break
        end
        q += 1
        if q > N
            push!(answers, copy(queen_positions))
            if is_fundamental(queen_positions, answers_fundamental, N)
                push!(answers_fundamental, copy(queen_positions))
            end
            q = N
            while move!(queen_positions, q, N)
                q -= 1
                if q == 0
                    end_flag = true
                    break
                end
            end
        end
    end
    return answers, answers_fundamental
end

using Plots
function main()
    N = 10
    num_answers = fill(0, N)
    num_answers_fundamental = fill(0, N)
    for i in 1:N
        answers, answers_fundamental = solve_nqueen(i)
        num_answers[i] = length(answers)
        num_answers_fundamental[i] = length(answers_fundamental)
    end

    plot(1:N, num_answers, label="all")
    scatter!(1:N, num_answers,primary=false)
    plot!(1:N, num_answers_fundamental, label="fundamental")
    scatter!(1:N, num_answers_fundamental,primary=false)
    title!("N-Queen")
    xlabel!("N")
    ylabel!("number of answers")
    savefig("nqueen.png")
end

main()

