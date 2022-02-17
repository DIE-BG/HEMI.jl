using DrWatson
@quickactivate "HEMI"

## Cargar datos de la base 2000 y 2010 del IPC 
using Dates, CSV, DataFrames
using CPIDataBase
using JLD2

## Carga de datos de archivos CSV
@info "Cargando archivos de datos..."
# Base 2000
gt_base00 = CSV.read(datadir("guatemala", "Guatemala_IPC_2000.csv"), DataFrame, normalizenames=true)
gt00gb = CSV.read(datadir("guatemala", "Guatemala_GB_2000.csv"), DataFrame, types=[String, String, Float64])
# Base 2010
gt_base10 = CSV.read(datadir("guatemala", "Guatemala_IPC_2010.csv"), DataFrame, normalizenames=true)
gt10gb = CSV.read(datadir("guatemala", "Guatemala_GB_2010.csv"), DataFrame, types=[String, String, Float64])

@info "Datos cargados exitosamente de archivos CSV"

## Construcción de estructuras de datos
# Base 2000
full_gt00_64 = FullCPIBase(gt_base00, gt00gb)
full_gt00_32 = convert(Float32, full_gt00_64)
var_gt00_64 = VarCPIBase(full_gt00_64)
var_gt00_32 = VarCPIBase(full_gt00_32)

# Base 2010
full_gt10_64 = FullCPIBase(gt_base10, gt10gb)
full_gt10_32 = convert(Float32, full_gt10_64)
var_gt10_64 = VarCPIBase(full_gt10_64)
var_gt10_32 = VarCPIBase(full_gt10_32)

# Estructura contenedora de datos del país
gtdata_32 = UniformCountryStructure(var_gt00_32, var_gt10_32)
gtdata_64 = UniformCountryStructure(var_gt00_64, var_gt10_64)

@info "Construcción exitosa de estructuras de datos" gtdata_32 gtdata_64

## Guardar datos para su carga posterior

# Guardar datos en formato JLD2 para su carga posterior 
@info "Guardando archivos de datos JLD2"

jldsave(datadir("guatemala", "gtdata32.jld2"); 
    # FullCPIBase    
    fgt00 = full_gt00_32, 
    fgt10 = full_gt10_32, 
    # VarCPIBase
    gt00 = var_gt00_32, 
    gt10 = var_gt10_32, 
    # UniformCountryStructure
    gtdata = gtdata_32, 
)

jldsave(datadir("guatemala", "gtdata64.jld2"); 
    # FullCPIBase    
    fgt00 = full_gt00_64, 
    fgt10 = full_gt10_64, 
    # VarCPIBase
    gt00 = var_gt00_64, 
    gt10 = var_gt10_64, 
    # UniformCountryStructure
    gtdata = gtdata_64, 
)

## Construcción de datos de prueba por defecto para el proyecto y la documentación
@info "Construcción de datos de prueba"

TEST_DATE = Date(2021, 12)
test_gtdata = gtdata_32[TEST_DATE]
test_gt00 = test_gtdata[1]
test_gt10 = test_gtdata[2]
test_fgt00 = full_gt00_32

f = full_gt10_32.dates .<= TEST_DATE
test_fgt10 = FullCPIBase(
    full_gt10_32.ipc[f, :], 
    full_gt10_32.v[f, :], 
    full_gt10_32.w, 
    full_gt10_32.dates[f], 
    full_gt10_32.baseindex, 
    full_gt10_32.codes, 
    full_gt10_32.names
)

jldsave(datadir("guatemala", "gtdata32_test.jld2"); 
    # FullCPIBase    
    fgt00 = test_fgt00, 
    fgt10 = test_fgt10, 
    # VarCPIBase
    gt00 = test_gt00, 
    gt10 = test_gt10, 
    # UniformCountryStructure
    gtdata = test_gtdata, 
)

# Copiar datos de prueba al directorio de datos de la documentación 
cp(
    datadir("guatemala", "gtdata32_test.jld2"), 
    projectdir("docs", "data", "guatemala", "gtdata32.jld2"),
    force=true    
)