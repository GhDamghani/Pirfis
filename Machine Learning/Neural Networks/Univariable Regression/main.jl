using Flux, CUDA, Statistics, ProgressMeter, Plots, JLD2

f(x) = sinc(x)

N = 1000

N_train = Int64(N * 0.8)
x_train = Float32.((rand(Float64, (1, N_train)) .- 0.5) .* 10)
y_train = Float32.(f.(x_train))

N_test = Int64(N * 0.2)
x_test = Float32.((rand(Float32, (1, N_test)) .- 0.5) .* 10)
y_test = Float32.(f.(x_test))

N_nodes = 20
model = Chain(Dense(1 => N_nodes, relu), BatchNorm(N_nodes), Dense(N_nodes => 1)) |> gpu


loader = Flux.DataLoader((x_train, y_train) |> gpu, batchsize=64, shuffle=true);
optim = Flux.setup(Flux.Adam(0.001), model)

losses = []
@showprogress for epoch in 1:1_000
    for (x, y) in loader
        loss, grads = Flux.withgradient(model) do m
            # Evaluate model and loss inside gradient context:
            y_hat = m(x)
            Flux.mse(y_hat, y)
        end
        Flux.update!(optim, model, grads[1])
        push!(losses, loss)
    end
end

# plot true data vs predicted
plot()
scatter!(x_test[1, :], y_test[1, :], label="true")
scatter!(x_test[1, :], (model(x_test |> gpu)|>cpu)[1, :], label="predicted")
println("Final trian loss: $(losses[end])")
println("Test loss: $(Flux.mse(model(x_test |> gpu) |> cpu, y_test))")
savefig("sinc.png")

model_state = Flux.state(model);
jldsave("mymodel.jld2"; model_state)