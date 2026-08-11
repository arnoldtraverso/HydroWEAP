#' Extraer temperatura media de NetCDF al formato WEAP
#'
#' Extrae temperaturas maximas y minimas desde archivos NetCDF grillados (por
#' ejemplo PISCOt), calcula el promedio areal por subcuenca y devuelve la
#' temperatura media `Tmed = (Tmax + Tmin) / 2`, que es la variable que utiliza
#' WEAP. El resultado se entrega como un `data.frame` listo para exportar.
#'
#' @param nc_tmax Ruta(s) a NetCDF de temperatura maxima, o un `SpatRaster`.
#' @param nc_tmin Ruta(s) a NetCDF de temperatura minima, o un `SpatRaster`.
#'   Debe cubrir exactamente el mismo periodo y numero de capas que `nc_tmax`.
#' @param subs Ruta a un shapefile de subcuencas, o un objeto `SpatVector` de
#'   poligonos.
#' @param field Nombre del campo de `subs` que contiene el codigo WEAP de cada
#'   subcuenca; se usa como nombre de columna en la salida.
#' @param dates Vector `Date` opcional con una fecha por capa temporal. Si es
#'   `NULL` (por defecto) las fechas se leen de la dimension de tiempo de
#'   `nc_tmax`.
#' @param digits Numero de decimales al que redondear los valores.
#' @param file Ruta opcional del CSV de salida. Si se indica, el resultado se
#'   escribe en formato WEAP con [write_weap_csv()] y el `data.frame` se
#'   devuelve de forma invisible.
#'
#' @return Un `data.frame` con columnas `Date`, `Year`, `Month`, `Day` y una
#'   columna de temperatura media por subcuenca. Si se indica `file`, se
#'   devuelve de forma invisible.
#' @export
#' @importFrom terra rast vect extract time
#'
#' @examples
#' \dontrun{
#' tmp2weap("tmax.nc", "tmin.nc", "subcuencas.shp", field = "Cod_WEAP",
#'          file = "Datos_tmed.csv")
#' }
tmp2weap <- function(nc_tmax, nc_tmin, subs, field, dates = NULL,
                     digits = 2, file = NULL) {
  grid_tx <- .as_spatraster(nc_tmax)
  grid_tn <- .as_spatraster(nc_tmin)
  subs    <- .as_spatvector(subs)

  if (!field %in% names(subs)) {
    stop("El campo '", field, "' no existe en 'subs'. Campos disponibles: ",
         paste(names(subs), collapse = ", "), call. = FALSE)
  }
  codes <- as.character(subs[[field]][, 1])
  dates <- .get_dates(grid_tx, dates)

  values_tx <- extract_areal(grid_tx, subs)
  values_tn <- extract_areal(grid_tn, subs)

  if (!identical(dim(values_tx), dim(values_tn))) {
    stop("Tmax y Tmin tienen distinto numero de capas o subcuencas; ",
         "revise que ambos cubran el mismo periodo.", call. = FALSE)
  }

  values_tm <- (values_tx + values_tn) / 2

  if (nrow(values_tm) != length(dates)) {
    warning(sprintf(
      "Las capas del NetCDF (%d) no coinciden con las fechas (%d).",
      nrow(values_tm), length(dates)), call. = FALSE)
  }

  df <- build_weap_df(values_tm, dates, codes, digits)

  if (!is.null(file)) {
    write_weap_csv(df, file)
    return(invisible(df))
  }
  df
}
