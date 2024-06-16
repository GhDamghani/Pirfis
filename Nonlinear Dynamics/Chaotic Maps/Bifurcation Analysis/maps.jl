function logistic!(x::Union{Array{Float64,1},Float64}, r::Float64, n::Int64=1)
    for _ in 1:n
        x = @. r * x * (1 - x)
    end
    return x
end