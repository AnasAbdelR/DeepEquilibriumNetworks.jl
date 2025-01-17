# DeepEquilibriumNetworks: (Fast) Deep Equilibrium Networks

DeepEquilibriumNetworks.jl is a framework built on top of
[DifferentialEquations.jl](https://docs.sciml.ai/DiffEqDocs/stable/) and
[Lux.jl](https://lux.csail.mit.edu/), enabling the efficient training and inference for
Deep Equilibrium Networks (Infinitely Deep Neural Networks).

## Installation

To install DeepEquilibriumNetworks.jl, use the Julia package manager:

```julia
using Pkg
Pkg.add("DeepEquilibriumNetworks")
```

## Quick-start

```julia
using DeepEquilibriumNetworks, Lux, Random, Zygote
# using LuxCUDA, LuxAMDGPU ## Install and Load for GPU Support

seed = 0
rng = Random.default_rng()
Random.seed!(rng, seed)
model = Chain(Dense(2 => 2),
    DeepEquilibriumNetwork(Parallel(+,
            Dense(2 => 2; use_bias=false),
            Dense(2 => 2; use_bias=false)),
        ContinuousDEQSolver(; abstol=0.1f0, reltol=0.1f0, abstol_termination=0.1f0,
            reltol_termination=0.1f0);
        save_everystep=true))

gdev = gpu_device()
cdev = cpu_device()

ps, st = Lux.setup(rng, model) |> gdev
x = rand(rng, Float32, 2, 1) |> gdev
y = rand(rng, Float32, 2, 1) |> gdev

model(x, ps, st)

gs = only(Zygote.gradient(p -> sum(abs2, first(first(model(x, p, st))) .- y), ps))
```

## Citation

If you are using this project for research or other academic purposes, consider citing our
paper:

```bibtex
@misc{pal2022mixing,
  title={Mixing Implicit and Explicit Deep Learning with Skip DEQs and Infinite Time Neural
         ODEs (Continuous DEQs)}, 
  author={Avik Pal and Alan Edelman and Christopher Rackauckas},
  year={2022},
  eprint={2201.12240},
  archivePrefix={arXiv},
  primaryClass={cs.LG}
}
```

For specific algorithms, check the respective documentations and cite the corresponding
papers.

## Contributing

  - Please refer to the
    [SciML ColPrac: Contributor's Guide on Collaborative Practices for Community Packages](https://github.com/SciML/ColPrac/blob/master/README.md)
    for guidance on PRs, issues, and other matters relating to contributing to SciML.

  - See the [SciML Style Guide](https://github.com/SciML/SciMLStyle) for common coding practices and other style decisions.
  - There are a few community forums:
    
      + The #diffeq-bridged and #sciml-bridged channels in the
        [Julia Slack](https://julialang.org/slack/)
      + The #diffeq-bridged and #sciml-bridged channels in the
        [Julia Zulip](https://julialang.zulipchat.com/#narrow/stream/279055-sciml-bridged)
      + On the [Julia Discourse forums](https://discourse.julialang.org)
      + See also [SciML Community page](https://sciml.ai/community/)

## Reproducibility

```@raw html
<details><summary>The documentation of this SciML package was built using these direct dependencies,</summary>
```

```@example
using Pkg # hide
Pkg.status() # hide
```

```@raw html
</details>
```

```@raw html
<details><summary>and using this machine and Julia version.</summary>
```

```@example
using InteractiveUtils # hide
versioninfo() # hide
```

```@raw html
</details>
```

```@raw html
<details><summary>A more complete overview of all dependencies and their versions is also provided.</summary>
```

```@example
using Pkg # hide
Pkg.status(; mode=PKGMODE_MANIFEST) # hide
```

```@raw html
</details>
```

```@eval
using TOML
using Markdown
version = TOML.parse(read("../../Project.toml", String))["version"]
name = TOML.parse(read("../../Project.toml", String))["name"]
link_manifest = "https://github.com/SciML/" *
                name *
                ".jl/tree/gh-pages/v" *
                version *
                "/assets/Manifest.toml"
link_project = "https://github.com/SciML/" *
               name *
               ".jl/tree/gh-pages/v" *
               version *
               "/assets/Project.toml"
Markdown.parse("""You can also download the
[manifest]($link_manifest)
file and the
[project]($link_project)
file.
""")
```
