# import Pkg; Pkg.add("Revise")
using Revise
includet("maps.jl")
using Plots

r_N = 500
r_arr = 2:(4-2)/(r_N-1):4
x_N = 1000
iter_N = 300

plot()
for (i, r) in enumerate(r_arr)
    global x_N, iter_N
    x = rand(x_N)
    x = logistic!(x, r, iter_N)
    scatter!([r for _ in 1:x_N], x, markersize=0.01, primary=false, legend=false)
end
savefig("bifurcation.png")