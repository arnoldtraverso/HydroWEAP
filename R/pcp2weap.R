#' Extraer precipitacion de un NetCDF al formato WEAP
#'
#' Extrae series de precipitacion desde uno o varios archivos NetCDF grillados
#' (por ejemplo PISCO), calculando el promedio areal dentro de cada subcuenca,
#' y devuelve un `data.frame` listo para exportar al formato WEAP.
#'
#' @param nc Ruta(s) a archivo(s) NetCDF, o un objeto `SpatRaster`. Si se pasan
#'   varias rutas se apilan en un unico `SpatRaster`.
#' @param subs Ruta a un shapefile de subcuencas, o un objeto `SpatVector` de
#'   poligonos.
#' @param field Nombre del campo de `subs` que contiene el codigo WEAP de cada
#'   subcuenca; se usa como nombre de columna en la salida.
#' @param dates Vector `Date` opcional con una fecha por capa temporal. Si es
#'   `NULL` (por defecto) las fechas se leen de la dimension de tiempo del
#'   NetCDF.
#' @param digits Numero de decimales al que redondear los valores.
#' @param file Ruta opcional del CSV de salida. Si se indica, el resultado se
#'   escribe en formato WEAP con [write_weap_csv()] y el `data.frame` se
#'   devuelve de forma invisible.
#' @param fun Funcion de agregacion aplicada a las celdas de cada subcuenca
#'   (por defecto la media aritmetica).
#'
#' @return Un `data.frame` con columnas `Date`, `Year`, `Month`, `Day` y una
#'   columna por subcuenca. Si se indica `file`, se devuelve de forma invisible.
#' @export
#' @importFrom terra rast vect extract time
#'
#' @examples
#' \dontrun{
#' # Devolver el data.frame en memoria
#' pcp <- pcp2weap("precip.nc", "subcuencas.shp", field = "Cod_WEAP")
#'
#' # Extraer y escribir el CSV de WEAP en un solo paso
#' pcp2weap("precip.nc", "subcuencas.shp", field = "Cod_WEAP",
#'          file = "Datos_pcp.csv")
#' }
pcp2weap <- function(nc, subs, field, dates = NULL, digits = 2,
                     file = NULL, fun = mean) {
  grid  <- .as_spatraster(nc)
  subs  <- .as_spatvector(subs)

  if (!field %in% names(subs)) {
    stop("El campo '", field, "' no existe en 'subs'. Campos disponibles: ",
         paste(names(subs), collapse = ", "), call. = FALSE)
  }
  codes <- as.character(subs[[field]][, 1])
  dates <- .get_dates(grid, dates)

  values <- extract_areal(grid, subs, fun = fun)

  if (nrow(values) != length(dates)) {
    warning(sprintf(
      "Las capas del NetCDF (%d) no coinciden con las fechas (%d).",
      nrow(values), length(dates)), call. = FALSE)
  }

  df <- build_weap_df(values, dates, codes, digits)

  if (!is.null(file)) {
    write_weap_csv(df, file)
    return(invisible(df))
  }
  df
}
