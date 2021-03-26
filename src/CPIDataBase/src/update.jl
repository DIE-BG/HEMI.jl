# update.jl - Funciones para lectura y descarga de datos

## Definiciones
const GT_DATA_FILE = "IPC-Guatemala.xlsx"
const GT_DF_FILE = "gt_00_10_df.jld"
const GT_JLD_FILE = "gt_00_10.jld"

# Rangos y hojas del archivo
# Rango de tabla de índices de precios base 2000 del IPC
const GT_RANGE_DATA_00 = (sheet = "2000", columns = "A:HK")
const GT_RANGE_GOODS_00 = (sheet = "GB2000", columns = "A:C")

# Rango de tabla de índices de precios base 2010 del IPC 
const GT_RANGE_DATA_10 = (sheet = "2010", columns = "A:JT")
const GT_RANGE_GOODS_10 = (sheet = "GB2010", columns = "A:C")


"""
    load_data(jld_file::AbstractString=GT_JLD_FILE)

Esta función permite cargar la variable `CountryStructure` guardada 
previamente en el archivo JLD `jld_file`. Por defecto, `jld_file = GT_JLD_FILE`, 
constante global con el valor `gt_00_10.jld`
"""
function load_data(jld_file::AbstractString=GT_JLD_FILE)
    # Cargar datos de Guatemala desde archivo JLD
    @info "Cargando archivo de datos de Guatemala"
    gt_data = JLD.load(jld_file, "gt_data")
    return gt_data
end

"""
    get_data(data_file::AbstractString, type::Type{<:AbstractFloat}=Float32)

Función para obtener los datos a partir de la lectura de DataFrames en el archivo
de Excel en `data_file`. Opcionalmente, es posible cambiar la precisión de los datos
con el parámetro `type`, cuyo valor por defecto es `Float32`.
"""
function get_data(data_file::AbstractString, type::Type{<:AbstractFloat}=Float32)
    # Cargar datos de Guatemala
    @info "Cargando archivo de datos de Guatemala"
    dfs = get_gt_dataframes(data_file, type)
    return CountryStructure(dfs...)
end

"""
    download_save_data(savepath::AbstractString)

Esta función descarga en el directorio `savepath`: 
- un archivo de Excel almacenado en Google Drive, 
- actualiza archivos JLD con la estructura de datos de país `gt_data` de tipo `CountryStructure` en el archivo `gt_00_10.jld`; y 
- adicionalmente, guarda los DataFrames de índices de precios y nombres de gastos básicos en el archivo `gt_00_10_df.jld`. 
"""
function download_save_data(savepath::AbstractString)
    # Se descarga el archivo de datos y procesando los DataFrames y datos como matrices
    @info "Descargando base de datos del IPC..."
    cpi_data_url_base = "https://docs.google.com/spreadsheets/d/1P_jMcrLfkUPo-uJdV6j6k9Y2ZSO1yukhi63jNYo60UA/export?format=xlsx"
    cpi_data_file = joinpath(savepath, GT_DATA_FILE)
    download(cpi_data_url_base, cpi_data_file)
    # Actualizamos los archivos de DataFrames y de estructura
    update_jld_files(cpi_data_file, savepath)
end

"""
    read_save_data(cpi_data_file::AbstractString, savepath::AbstractString)

Esta función lee el archivo de Excel en `cpi_data_file` y guarda en el directorio `savepath`: 
- actualización de archivos JLD con la estructura de datos de país `gt_data` de tipo `CountryStructure` en el archivo `gt_00_10.jld`; y 
- adicionalmente, guarda los DataFrames de índices de precios y nombres de gastos básicos en el archivo `gt_00_10_df.jld`. 
"""
function read_save_data(cpi_data_file::AbstractString, savepath::AbstractString)
    # We create the artifact descargando el archivo de datos y procesando los DataFrames y datos como matrices
    @info "Leyendo base de datos del IPC desde $cpi_data_file"
    # Actualizamos los archivos de DataFrames y de estructura
    update_jld_files(cpi_data_file, savepath)
end

"""
    update_jld_files(data_file, savepath)

Función de ayuda para actualizar archivos JLD a partir de archivo de Excel en `data_file`. 
Los archivos JLD son guardados en el directorio especificado por `savepath`
"""
function update_jld_files(data_file::AbstractString, savepath::AbstractString)
    # Guardar DataFrames
    @info "Actualización de DataFrames de gastos básicos..."
    (df_00, gb_00, df_10, gb_10) = get_gt_dataframes(data_file)
    JLD.save(joinpath(savepath, GT_DF_FILE), "df_00", df_00, "df_10", df_10, "gb_00", gb_00, "gb_10", gb_10)

    # Matrices de índices de precios, variaciones intermensuales y ponderaciones
    @info "Actualización de estructura de datos..."
    gt_data = GTStructure(df_00, gb_00, df_10, gb_10)
    JLD.save(joinpath(savepath, GT_JLD_FILE), "gt_data", gt_data)

end

"""
    get_gt_dataframes(data_file::AbstractString, type::Type{<:AbstractFloat}=Float32)

Función de ayuda para leer y extraer del archivo de Excel en `data_file`, los DataFrames
de índices de precios y gastos básicos, junto con sus ponderaciones en el conjunto de DataFrames
`(df_00, gb_00, df_10, gb_10)`. Opcionalmente, es posible cambiar la precisión de los datos con 
el parámetro `type`, cuyo valor por defecto es `Float32`.
"""
function get_gt_dataframes(data_file::AbstractString, type::Type{<:AbstractFloat}=Float32)

    # Leer datos del IPC base 2000
    df_00, gb_00 = get_single_base_dataframe(data_file, GT_RANGE_DATA_00, GT_RANGE_GOODS_00, type)
    # Leer datos del IPC base 2010
    df_10, gb_10 = get_single_base_dataframe(data_file, GT_RANGE_DATA_10, GT_RANGE_GOODS_10, type)

    return (df_00, gb_00, df_10, gb_10)
end


"""
    get_single_base_dataframe(data_file::AbstractString, range_data::NamedTuple, range_goods::NamedTuple, type::Type{<:AbstractFloat}=Float32) 

Función wrapper para leer un archivo de Excel `data_file` con al menos dos hojas: 
- Una hoja con una matriz de índices de precios en las columnas y períodos en las filas. Este parámetro debe especificarse en una tupla `range_data` con campos `sheet` y `columns`. Por ejemplo `rd = (sheet = "2000", columns = "A:HK")`.
    - La primera fila corresponde al campo `Fecha` y códigos de los gastos básicos. 
    - La columna de `Fecha` debe tener formato `yyyy-MM-dd`.
- Una hoja con la lista de gastos básicos que corresponden a los códigos especificados en la hoja anterior. Debe tener tres columnas:
    - `Código`: con los códigos correspondientes a los gastos básicos
    - `GastoBasico`: con los nombres de los gastos básicos.
    - `Ponderación`: con las ponderaciones en el IPC de los gastos básicos.
"""
function get_single_base_dataframe(data_file::AbstractString, range_data::NamedTuple, range_goods::NamedTuple, type::Type{<:AbstractFloat}=Float32) 
    # Función para obtener nombres de columnas si codigos son numéricos
    function normalize_names(colname)
        if startswith(colname, r"\d+")
            return "_"*colname
        end
        return colname
    end

    # Leer datos del IPC
    df_ipc = DataFrame(XLSX.readtable(data_file, range_data.sheet, range_data.columns)...)
    dropmissing!(df_ipc, disallowmissing=true)
    df_ipc[!, :Fecha] = map(Date, df_ipc[!, :Fecha])
    df_ipc[!, 2:end] = convert(Matrix{type}, df_ipc[!,2:end])
    rename!(normalize_names, df_ipc)

    # Nombres de gastos básicos de la base del IPC y sus ponderaciones
    df_gb = DataFrame(XLSX.readtable(data_file, range_goods.sheet, range_goods.columns, infer_eltypes=true)...)
    df_gb[!, :Codigo] = "_" .* df_gb[!, :Codigo]
    df_gb[!, :Ponderacion] = convert.(type, df_gb[!, :Ponderacion])
    return (df_ipc, df_gb)
end