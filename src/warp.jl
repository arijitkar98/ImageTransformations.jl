"""
    warp(img, tform, [indices], [degree = Linear()], [fill = NaN]) -> imgw

Transform the coordinates of `img`, returning a new `imgw`
satisfying `imgw[I] = img[tform(I)]`. This approach is known as
backward mode warping. The transformation `tform` must accept a
`SVector` as input. A useful package to create a wide variety of
such transformations is
[CoordinateTransformations.jl](https://github.com/FugroRoames/CoordinateTransformations.jl).

# Reconstruction scheme

During warping, values for `img` must be reconstructed at
arbitrary locations `tform(I)` which do not lie on to the lattice
of pixels. How this reconstruction is done depends on the type of
`img` and the optional parameter `degree`.

When `img` is a plain array, then on-grid b-spline interpolation
will be used. It is possible to configure what degree of b-spline
to use with the parameter `degree`. For example one can use
`degree = Linear()` for linear interpolation, `degree =
Constant()` for nearest neighbor interpolation, or `degree =
Quadratic(Flat())` for quadratic interpolation.

In the case `tform(I)` maps to indices outside the original
`img`, those locations are set to a value `fill` (which defaults
to `NaN` if the element type supports it, and `0` otherwise). The
parameter `fill` also accepts extrapolation schemes, such as
`Flat()`, `Periodic()` or `Reflect()`.

For more control over the reconstruction scheme --- and how
beyond-the-edge points are handled --- pass `img` as an
`AbstractInterpolation` or `AbstractExtrapolation` from
[Interpolations.jl](https://github.com/JuliaMath/Interpolations.jl).

# The meaning of the coordinates

The output array `imgw` has indices that would result from
applying `inv(tform)` to the indices of `img`. This can be very
handy for keeping track of how pixels in `imgw` line up with
pixels in `img`.

If you just want a plain array, you can "strip" the custom
indices with `parent(imgw)`.

# Examples: a 2d rotation (see JuliaImages documentation for pictures)

```
julia> using Images, CoordinateTransformations, TestImages, OffsetArrays

julia> img = testimage("lighthouse");

julia> indices(img)
(Base.OneTo(512),Base.OneTo(768))

# Rotate around the center of `img`
julia> tfm = recenter(RotMatrix(-pi/4), center(img))
AffineMap([0.707107 0.707107; -0.707107 0.707107], [-196.755,293.99])

julia> imgw = warp(img, tfm);

julia> indices(imgw)
(-196:709,-68:837)

# Alternatively, specify the origin in the image itself
julia> img0 = OffsetArray(img, -30:481, -384:383);  # origin near top of image

julia> rot = LinearMap(RotMatrix(-pi/4))
LinearMap([0.707107 -0.707107; 0.707107 0.707107])

julia> imgw = warp(img0, rot);

julia> indices(imgw)
(-293:612,-293:611)

julia> imgr = parent(imgw);

julia> indices(imgr)
(Base.OneTo(906),Base.OneTo(905))
```
"""
function warp(img::AbstractExtrapolation{T}, tform, inds::Tuple = autorange(img, inv(tform))) where T
    out = similar(Array{T}, inds)
    warp!(out, img, tform)
end

function warp!(out, img::AbstractExtrapolation, tform)
    @inbounds for I in CartesianRange(indices(out))
        out[I] = _getindex(img, tform(SVector(I.I)))
    end
    out
end

function warp(img::AbstractArray, tform, inds::Tuple, args...)
    etp = box_extrapolation(img, args...)
    warp(etp, tform, inds)
end

function warp(img::AbstractArray, tform, args...)
    etp = box_extrapolation(img, args...)
    warp(etp, tform)
end

@deprecate warp_new(img::AbstractArray, tform, args...) warp(img, tform, args...)
@deprecate warp_old(img::AbstractArray, tform, args...) warp(img, inv(tform), args...)
