# add JpegTurbo, ImageIO
using FileIO, TestImages, ImageCore, ImageFiltering, Images, Colors, ProgressMeter

function main()
    img = testimage("lighthouse")
    img = imresize(img, ratio=1 / 2)
    n = Int(size(img)[2] / 2)
    new_img = copy(img)

    @showprogress for _ = 1:n
        new_img = SeamCarve(new_img)
    end

    resized = imresize(img, (size(img)[1], size(img)[2] - Int(size(img)[2] / 2)))

    save("output.png", new_img)
    save("comparison.png", mosaic(img, new_img, resized; nrow=1))
end

function SeamCarve(img)
    img_size = size(img)
    b = Float32.(Gray.(img))
    img_cum_energy = fill(0.0, img_size[1], img_size[2])
    Sy, Sx = Kernel.sobel()
    ∇y = imfilter(b, Sy)
    ∇x = imfilter(b, Sx)
    img_edge = sqrt.(∇x .^ 2 + ∇y .^ 2)
    for i in img_size[1]:-1:1
        @simd for j in 1:img_size[2]
            if i == img_size[1]
                img_cum_energy[i, j] = img_edge[i, j]
            else
                if j == 1
                    m = minimum(img_cum_energy[i+1, j:j+1])
                elseif j == img_size[2]
                    m = minimum(img_cum_energy[i+1, j-1:j])
                else
                    m = minimum(img_cum_energy[i+1, j-1:j+1])
                end
                img_cum_energy[i, j] = m + img_edge[i, j]
            end
        end
    end
    seam = fill(0, img_size[1])
    for i in 1:img_size[1]
        if i == 1
            seam[i] = sortperm(img_cum_energy[1, :])[1]
        else
            if seam[i-1] == 1
                m = sortperm(img_cum_energy[i, 1:seam[i-1]+1])[1] + 1
            elseif seam[i-1] == img_size[2]
                m = sortperm(img_cum_energy[i, seam[i-1]-1:img_size[2]])[1] - 1
            else
                m = sortperm(img_cum_energy[i, seam[i-1]-1:seam[i-1]+1])[1]
            end
            seam[i] = seam[i-1] + m - 2
        end
    end
    img_arr = Float32.(channelview(img))
    new_img = fill(RGB(0, 0, 0), img_size[1], img_size[2] - 1)
    @simd for i in 1:img_size[1]
        new_img[i, :] = reduce(hcat, [RGB(img_arr[1, i, x], img_arr[2, i, x], img_arr[3, i, x]) for x in 1:img_size[2] if x != seam[i]])
    end
    return new_img
end


main()