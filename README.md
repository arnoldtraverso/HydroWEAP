# HydroWEAP

Herramientas en R para extraer series de **precipitación** y **temperatura**
desde datos grillados en NetCDF (por ejemplo [PISCO](https://piscoprec.github.io/))
agregadas por subcuenca, y exportarlas directamente al formato CSV
`ReadFromFile` que utiliza el modelo hidrológico
[WEAP](https://www.weap21.org/) (Water Evaluation And Planning).

## Instalación

```r
# install.packages("remotes")
remotes::install_github("arnoldtraverso/HydroWEAP")
```

Requiere el paquete [`terra`](https://rspatial.github.io/terra/).

## Uso

### Precipitación

```r
library(HydroWEAP)

pcp2weap(
  nc    = "DATOS_PCP.nc",              # NetCDF de precipitación
  subs  = "Cuenca_Sama.shp",          # shapefile de subcuencas
  field = "Cod_WEAP",                 # campo con el código WEAP
  file  = "Datos_pcp_sama.csv"        # CSV de salida en formato WEAP
)
```

### Temperatura media

WEAP usa temperatura media. `tmp2weap()` extrae Tmax y Tmin y calcula
`Tmed = (Tmax + Tmin) / 2`. Acepta una carpeta con varios `.nc`:

```r
nc_tmax <- list.files("T_Max/", pattern = "\\.nc$", full.names = TRUE)
nc_tmin <- list.files("T_Min/", pattern = "\\.nc$", full.names = TRUE)

tmp2weap(
  nc_tmax = nc_tmax,
  nc_tmin = nc_tmin,
  subs    = "Cuenca_Sama.shp",
  field   = "Cod_WEAP",
  file    = "Datos_tmed_sama.csv"
)
```

### Obtener el `data.frame` sin escribir archivo

Si se omite `file`, las funciones devuelven un `data.frame` que se puede
inspeccionar o escribir aparte con `write_weap_csv()`:

```r
pcp <- pcp2weap("DATOS_PCP.nc", "Cuenca_Sama.shp", field = "Cod_WEAP")
head(pcp)
write_weap_csv(pcp, "Datos_pcp.csv")
```

## Formato de salida (WEAP `ReadFromFile`)

```
"$ListSeparator = ,",,,,
$DecimalSymbol = .,,,,
$DateFormat = yyyy-mm-dd,,,,
$Columns = Date,Year,Month,Day,Sch_1,Sch_2,...
1981-01-01,1981,1,1,43.75,59.21
1981-02-01,1981,2,1,59.00,42.65
```

## Funciones

| Función           | Descripción                                                  |
|-------------------|--------------------------------------------------------------|
| `pcp2weap()`      | Extrae precipitación por subcuenca al formato WEAP.          |
| `tmp2weap()`      | Extrae temperatura media (Tmax/Tmin) por subcuenca a WEAP.   |
| `write_weap_csv()`| Escribe un `data.frame` en el formato CSV de WEAP.           |

## Licencia

GPL-2.
