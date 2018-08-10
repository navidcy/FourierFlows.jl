using FourierFlows, PyPlot, JLD2

import FourierFlows.TracerAdvDiff

# Numerical parameters and time-stepping parameters
nx  = 128         # 2D resolution = nx^2
stepper = "RK4"   # timestepper
dt  = 0.02        # timestep
nsubs  = 200      # number of time-steps for plotting
nsteps = 4nsubs   # total number of time-steps (must be multiple of nsubs)

# Physical parameters
Lx  = 2π      # domain size
kap = 0.002   # diffusivity

gr = TwoDGrid(nx, Lx)
X, Y = gr.X, gr.Y

# streamfunction (for plotting) and (u,v) flow field
psiampl = 0.2
m, n = 1, 1
psiin = @. psiampl * cos(m*X) * cos(n*Y)
uvel(x, y) = +psiampl * n * cos(m*x) * sin(n*y)
vvel(x, y) = -psiampl * m * sin(m*x) * cos(n*y)

prob = TracerAdvDiff.ConstDiffProblem(; steadyflow=true,
    nx=nx, Lx=Lx, kap=kap, u=uvel, v=vvel, dt=dt, stepper=stepper)

s, v, p, g, eq, ts = prob.state, prob.vars, prob.params, prob.grid, prob.eqn, prob.ts;

# Initial condition c0 = c(x, y, t=0)
amplc0, sigc0 = 0.1, 0.1
x0, y0 = 1.2, 0
c0func(x, y) = amplc0*exp(-(x^2+y^2)/(2sigc0^2))
c0 = c0func.(g.X .- x0, g.Y .- y0)

TracerAdvDiff.set_c!(prob, c0)

"Plot the concentration field and the (u, v) streamlines."
function plotoutput(prob, fig, axs; drawcolorbar=false)
  s, v, p, g = prob.state, prob.vars, prob.params, prob.grid
  t = round(prob.state.t, digits=2)

  TracerAdvDiff.updatevars!(prob)

  cla()
  pcolormesh(g.X, g.Y, v.c)

  if drawcolorbar; colorbar(); end

  contour(g.X, g.Y, psiin, 15, colors="k", linewidths=0.7)
  axis("equal")
  axis("square")
  title("shading: \$c(x, y, t= $t )\$, contours: \$\\psi(x, y)\$")

  pause(0.001)

  nothing
end

fig, axs = subplots(ncols=1, nrows=1, figsize=(8, 8))
plotoutput(prob, fig, axs; drawcolorbar=true)

while prob.step < nsteps
  stepforward!(prob, nsubs)
  plotoutput(prob, fig, axs)
end
