###############################################################################
# Ejemplo de uso del paquete HydroWEAP
# Extraccion de precipitacion y temperatura media al formato WEAP.
###############################################################################

library(HydroWEAP)

# ---------------------------------------------------------------------------
# 1. Precipitacion
# ---------------------------------------------------------------------------
# Extrae la precipitacion de un NetCDF por subcuenca y escribe el CSV de WEAP.
pcp2weap(
  nc    = "F:/.../DATOS_PCP.nc",       # NetCDF de precipitacion
  subs  = "D:/Sama/01_SIG/Cuenca_Sama.shp",
  field = "Cod_WEAP",                  # campo con el codigo WEAP
  file  = "Datos_pcp_sama.csv"         # CSV de salida en formato WEAP
)

# ---------------------------------------------------------------------------
# 2. Temperatura media (Tmed = (Tmax + Tmin) / 2)
# ---------------------------------------------------------------------------
# Acepta una carpeta con varios .nc usando list.files():
nc_tmax <- list.files("F:/Temp_PISCO2022/T_Max/", pattern = "\\.nc$", full.names = TRUE)
nc_tmin <- list.files("F:/Temp_PISCO2022/T_Min/", pattern = "\\.nc$", full.names = TRUE)

tmp2weap(
  nc_tmax = nc_tmax,
  nc_tmin = nc_tmin,
  subs    = "D:/Sama/01_SIG/Cuenca_Sama.shp",
  field   = "Cod_WEAP",
  file    = "Datos_tmed_sama.csv"
)

# ---------------------------------------------------------------------------
# 3. Uso alternativo: obtener el data.frame y escribir aparte
# ---------------------------------------------------------------------------
pcp <- pcp2weap("precip.nc", "subcuencas.shp", field = "Cod_WEAP")
head(pcp)
write_weap_csv(pcp, "Datos_pcp.csv")
