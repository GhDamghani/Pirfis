# add JpegTurbo, ImageIO
using FileIO, TestImages, ImageCore, ImageView, ImageFiltering, Images, Colors, ProgressMeter, Statistics

function main()
    img = testimage("chelsea.png")
    img_supers = []

    n_sps = (500, 1000, 5000)

    for n_sp in n_sps
        m_pixel, l = SLIC(img, n_sp)
        img_super = superpixel(img, m_pixel, l)
        push!(img_supers, img_super)
    end

    save("comparison.png", mosaic(img_supers..., img; nrow=2, ncol=2))
end

d_s(A, B) = ((A .- B) .^ 2) |> sum |> sqrt
d_c(A, B) = ((A .- B) .^ 2) |> sum |> sqrt
D(A_xy, B_xy, A_pixel, B_pixel, S, m=1) = sqrt(d_c(A_pixel, B_pixel)^2 + (m * d_s(A_xy, B_xy) / S)^2)

function SLIC(img, n_sp, compactness=1)
    # initializing
    height, width = size(img)
    N = length(img)
    S = N / n_sp |> sqrt |> ceil |> Int
    img = channelview(img)

    m_pixel = []
    m_xy = []

    sampling_x = range(3, step=S, stop=height - 2)
    sampling_y = range(3, step=S, stop=width - 2)

    kernel = Array{Float32,2}([-1 -1 -1; -1 8 -1; -1 -1 -1])
    kernel = permutedims(cat(kernel, kernel, kernel; dims=3), (3, 1, 2))
    for x in sampling_x, y in sampling_y
        neighbor = img[:, x-2:x+2, y-2:y+2]

        neighbor_grad = fill(0.0, 3, 3)
        for i in 1:3, j in 1:3
            neighbor_grad[i, j] = neighbor[:, i:i+2, j:j+2] .* kernel |> sum |> abs
        end
        lowest_grad = argmin(neighbor_grad)

        pixel = neighbor[:, lowest_grad+CartesianIndex(1, 1)]

        push!(m_pixel, pixel)
        push!(m_xy, [x, y])
    end

    l = fill(-1, height, width)
    d = fill(Inf, height, width)
    E = Inf
    threshold = 0.005

    for it in 1:100
        for c in eachindex(m_pixel)
            x, y = m_xy[c]

            for i in 1:2*S, j in 1:2*S
                u, v = x - S + i, y - S + j
                if u < 1 || u > height || v < 1 || v > width
                    continue
                end
                D_ij = D(m_xy[c], (u, v), m_pixel[c], img[:, u, v], S, compactness)
                if D_ij < d[u, v]
                    d[u, v] = D_ij
                    l[u, v] = c
                end
            end
        end

        # Update
        previous_centers = copy(m_xy)
        for c in eachindex(m_pixel)
            cluster = findall(l .== c)
            m_pixel[c] = vec(mean(img[:, cluster], dims=(2, 3)))
            m_xy[c] = mean(a -> [a[1], a[2]], cluster) .|> round .|> Int
        end


        # Residual Error
        E = (m_xy .- previous_centers) .|> (a -> sqrt(sum(a .^ 2))) |> mean

        if E < threshold
            break
        end
    end
    m_pixel = m_pixel .|> (a -> RGB{N0f8}(a[1], a[2], a[3]))
    return m_pixel, l

end

function superpixel(img, m_pixel, l)
    img_super = copy(img)

    for i in eachindex(l)
        img_super[i] = m_pixel[l[i]]
    end

    return img_super
end


main()