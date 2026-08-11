# Helpers internos del paquete HydroWEAP -------------------------------------

#' Normalizar entrada a SpatRaster
#'
#' @param x Ruta(s) a NetCDF/raster o un objeto `SpatRaster`.
#' @return Un `SpatRaster`.
#' @importFrom terra rast
#' @keywords internal
#' @noRd
.as_spatraster <- function(x) {
  if (inherits(x, "SpatRaster")) x else terra::rast(x)
}

#' Normalizar entrada a SpatVector
#'
#' @param x Ruta a un shapefile o un objeto `SpatVector`.
#' @return Un `SpatVector`.
#' @importFrom terra vect
#' @keywords internal
#' @noRd
.as_spatvector <- function(x) {
  if (inherits(x, "SpatVector")) x else terra::vect(x)
}

#' Obtener el vector de fechas
#'
#' Toma las fechas del argumento `dates` si se proporciona; en caso contrario
#' las lee de la dimension de tiempo del `SpatRaster`.
#'
#' @param grid `SpatRaster` del que leer el tiempo si `dates` es `NULL`.
#' @param dates Vector `Date` opcional.
#' @return Un vector `Date`.
#' @importFrom terra time
#' @keywords internal
#' @noRd
.get_dates <- function(grid, dates = NULL) {
  if (is.null(dates)) dates <- terra::time(grid)
  if (length(dates) == 0 || all(is.na(dates))) {
    stop("El NetCDF no trae una dimension de tiempo valida; ",
         "pase el argumento 'dates' explicitamente.", call. = FALSE)
  }
  as.Date(dates)
}

#' Extraer el promedio areal por poligono
#'
#' Para cada capa de un `SpatRaster` calcula el valor agregado (por defecto la
#' media aritmetica) de las celdas contenidas en cada poligono de `subs`.
#'
#' @param grid `SpatRaster` con una o mas capas temporales.
#' @param subs `SpatVector` de poligonos (subcuencas).
#' @param fun Funcion de agregacion aplicada a las celdas de cada poligono.
#' @param na.rm Logico; si `TRUE` ignora `NA` en la agregacion.
#' @return Matriz numerica con filas = capas (tiempo) y columnas = poligonos.
#' @importFrom terra extract
#' @keywords internal
#' @noRd
extract_areal <- function(grid, subs, fun = mean, na.rm = TRUE) {
  ext <- terra::extract(grid, subs, fun = fun, na.rm = na.rm, ID = FALSE)
  t(as.matrix(ext))
}

#' Construir un data.frame en formato WEAP
#'
#' Antepone las columnas `Date`, `Year`, `Month` y `Day` a la matriz de
#' valores y asigna los codigos WEAP como nombres de columna.
#'
#' @param values Matriz `[tiempo x subcuencas]`.
#' @param dates Vector `Date` de la misma longitud que las filas de `values`.
#' @param codes Vector de codigos WEAP, uno por columna de `values`.
#' @param digits Numero de decimales al que redondear los valores.
#' @return `data.frame` con columnas `Date`, `Year`, `Month`, `Day` y una por
#'   subcuenca.
#' @keywords internal
#' @noRd
build_weap_df <- function(values, dates, codes, digits = 2) {
  values <- round(values, digits)
  colnames(values) <- codes
  data.frame(
    Date  = format(dates, "%Y-%m-%d"),
    Year  = as.integer(format(dates, "%Y")),
    Month = as.integer(format(dates, "%m")),
    Day   = as.integer(format(dates, "%d")),
    values,
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}
