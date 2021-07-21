# # Script de prueba para tipos que especifican variantes de simulación
using DrWatson
@quickactivate "HEMI"

# Cargar el módulo de Distributed para computación paralela
using Distributed
# Agregar procesos trabajadores
addprocs(4, exeflags="--project")

# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI

"""
Evaluación de Inflación Subyacente de Exclusión Fija Óptima DIE. 
1. Definir mayores volatilidades de las bases 2000 y 2010.
2. Definir algoritmo para evaluación.
3. Exploración inicial base 2000 y 2010 (¿10,000 simulaciones en cada evaluación?)

"""