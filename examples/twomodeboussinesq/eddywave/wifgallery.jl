include("./setup.jl")

function rungallerysimulation(α, nkw;
      n = 256,
      L = 2π*1600e3,
      ε = 1e-1,           # Wave amplitude
     Ro = 1e-1,           # Eddy Rossby number
  Reddy = L/20,           # Eddy radius
   name = "gallery"
)

  # Setup
  ew = EddyWave(name, L, α, ε, Ro, Reddy; nkw=nkw, dtfrac=1e-2, nsubperiods=4,
    nν0=8, nν1=8, ν0=1e32, ν1=1e16, nperiods=24) 

  prob, diags, outs = eddywavesetup(n, ew)
  etot, e0, e1 = diags[1], diags[2], diags[3]

  # Run
  startwalltime = time()
  while prob.step < ew.nsteps

    stepforward!(prob, diags; nsteps=ew.nsubs)
    TwoModeBoussinesq.updatevars!(prob)
    saveoutput(outs)

    walltime = (time()-startwalltime)/60

    log1 = @sprintf("step: %04d, t: %d, ", prob.step, prob.t/ew.twave)
    log2 = @sprintf("ΔE: %.3f, Δe: %.3f, Δ(E+e): %.6f, τ: %.2f min",
      e0.value/e0.data[1], e1.value/e1.data[1], etot.value/etot.data[1],
      walltime)

    println(log1*log2)

    plotmsg1 = @sprintf("\$t=% 3d\$ wave periods, \$\\Delta E=%.3f\$, ",
      round(Int, prob.t/ew.twave), e0.value/e0.data[1])
    plotmsg2 = @sprintf("\$\\Delta e=%.3f\$, \$\\Delta(E+e)=%.6f\$",
      e1.value/e1.data[1], etot.value/etot.data[1])

    makefourplot(prob, ew; message=plotmsg1*plotmsg2, save=true,
      plotpath="./wifgallery") 
  end

  nothing
end

# -- Parameters --
nkwgallery = [    4,    8,   16,   16,   16,   16,   16 ] 
  αgallery = [ 0.02, 0.02, 0.02, 0.50, 1.00, 3.00, 8.00 ] 

for (ig, α) in enumerate(αgallery)
  nkw = nkwgallery[ig]
  rungallerysimulation(α, nkw; n=512)
end
