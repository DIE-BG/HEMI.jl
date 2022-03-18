# Script de actualización de dependencias
using DrWatson
@quickactivate "HEMI"
import Pkg 

# Opción para actualizar los entornos
UPDATE = true

## Proyecto principal 
@info "Actualización de paquetes del proyecto"
ROOTDIR = projectdir()
Pkg.activate(ROOTDIR)
Pkg.status()
UPDATE && Pkg.update()

## Paquetes internos 
@info "Actualización de paquetes del paquete interno InflationEvalTools"
Pkg.activate(joinpath(ROOTDIR, "src", "InflationEvalTools"))
Pkg.status()
if UPDATE 
    Pkg.update()
    Pkg.activate(ROOTDIR)
    Pkg.resolve()
end

## Documentación 
@info "Actualización de documentación"
Pkg.activate(joinpath(ROOTDIR, "docs"))
Pkg.status()
Pkg.resolve()
UPDATE && Pkg.update()

## Activar el entorno del proyecto
Pkg.activate(ROOTDIR)
