###############################################################################
# Pcp2WEAP.R
# Extraccion de precipitaciones desde un NetCDF a nivel de subcuencas
# y exportacion en el formato de lectura de WEAP (ReadFromFile).
#
# El CSV de salida replica el formato:
#   $ListSeparator = ,
#   $DecimalSymbol = .
#   $DateFormat = yyyy-mm-dd
#   $Columns = Date,Year,Month,Day,<Cod_WEAP_1>,<Cod_WEAP_2>,...
#   1964-01-01,1964,1,1,val1,val2,...
###############################################################################

library(tidyverse)
library(raster)
library(ncdf4)
library(hydroTSM)

rm(list = ls())

# ---------------------------------------------------------------------------
# PARAMETROS (editar segun corresponda)
# ---------------------------------------------------------------------------
dir_trabajo <- "D:/Sama/Modelo Weap/"
ruta_shp    <- "D:/Sama/01_SIG/Cuenca_Sama.shp"
ruta_nc     <- "F:/Nueva carpeta (3)/TRABAJO-2024/Estudio_Hidrologico_Locumba/Analisis de precipitaciones/Kriging_raster/DATOS_PCP.nc"
campo_weap  <- "Cod_WEAP"            # campo del shapefile con el codigo WEAP
fecha_ini   <- as.Date("1964-01-01")
fecha_fin   <- as.Date("2024-12-31")
paso        <- "month"               # "month" o "day"
n_cores     <- 4
n_decimales <- 2
ruta_salida <- "Datos_pcp_sama.csv"

# ---------------------------------------------------------------------------
# EJECUCION
# ---------------------------------------------------------------------------
setwd(dir_trabajo); getwd()

# Cargar el shapefile de subcuencas
Shp_bsn <- shapefile(x = ruta_shp)
plot(Shp_bsn)

# Cargar el NetCDF de precipitaciones
grid_pcp <- raster::brick(x = ruta_nc)

# Ejecutar el proceso de extraccion
datos_pcp <- pcp2weap(grid = grid_pcp, subs = Shp_bsn, cores = n_cores) %>%
  round(digits = n_decimales)

# Nombres de columna = codigos WEAP de cada subcuenca
codigos_weap <- as.character(Shp_bsn@data[[campo_weap]])
colnames(datos_pcp) <- codigos_weap

# Secuencia de fechas (primer dia de cada periodo)
Dates_d <- seq.Date(from = fecha_ini, to = fecha_fin, by = paso)

# Verificacion: filas del NetCDF vs fechas generadas
if (nrow(datos_pcp) != length(Dates_d)) {
  warning(sprintf(
    "Numero de capas del NetCDF (%d) no coincide con las fechas generadas (%d). Revisa fecha_ini/fecha_fin/paso.",
    nrow(datos_pcp), length(Dates_d)))
}

# Data frame final en formato WEAP: Date, Year, Month, Day, <subcuencas>
datos_weap <- data.frame(
  Date  = format(Dates_d, "%Y-%m-%d"),
  Year  = as.integer(format(Dates_d, "%Y")),
  Month = as.integer(format(Dates_d, "%m")),
  Day   = as.integer(format(Dates_d, "%d")),
  datos_pcp,
  check.names = FALSE,
  stringsAsFactors = FALSE
)

head(datos_weap)

# Guardar en formato WEAP
write_weap_csv(datos_weap, file = ruta_salida)

cat("Archivo guardado en:", normalizePath(ruta_salida), "\n")

