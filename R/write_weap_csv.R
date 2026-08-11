#' Escribir un data.frame en formato CSV de WEAP
#'
#' Escribe un `data.frame` en el formato de texto delimitado por comas que lee
#' el modelo WEAP mediante la funcion `ReadFromFile`. El archivo incluye las
#' cuatro directivas de cabecera (`$ListSeparator`, `$DecimalSymbol`,
#' `$DateFormat` y `$Columns`) seguidas de los datos.
#'
#' El `data.frame` de entrada debe tener como primeras columnas `Date`, `Year`,
#' `Month` y `Day`, y a continuacion una columna por subcuenca. Habitualmente
#' se genera con [pcp2weap()] o [tmp2weap()].
#'
#' @param df `data.frame` con columnas `Date`, `Year`, `Month`, `Day` y una por
#'   subcuenca (por ejemplo la salida de [pcp2weap()] o [tmp2weap()]).
#' @param file Ruta del archivo CSV de salida.
#'
#' @return Devuelve `file` de forma invisible.
#' @export
#' @importFrom utils write.table
#'
#' @examples
#' \dontrun{
#' df <- pcp2weap("precip.nc", "subcuencas.shp", field = "Cod_WEAP")
#' write_weap_csv(df, "Datos_pcp.csv")
#' }
write_weap_csv <- function(df, file) {
  requeridas <- c("Date", "Year", "Month", "Day")
  if (!all(requeridas %in% colnames(df))) {
    stop("'df' debe contener las columnas: ",
         paste(requeridas, collapse = ", "), call. = FALSE)
  }

  n_total <- ncol(df)                 # total de columnas (4 + n subcuencas)
  relleno <- strrep(",", n_total - 1) # comas para completar la fila

  # Cabeceras (directivas) de WEAP
  cab <- c(
    paste0("\"$ListSeparator = ,\"", relleno),
    paste0("$DecimalSymbol = .",     relleno),
    paste0("$DateFormat = yyyy-mm-dd", relleno),
    paste0("$Columns = ", paste(colnames(df), collapse = ","))
  )

  con <- file(file, open = "w", encoding = "UTF-8")
  on.exit(close(con))
  writeLines(cab, con)

  # Datos (sin cabecera de columnas, sin comillas, NA como vacio)
  utils::write.table(df, file = con, sep = ",",
                     row.names = FALSE, col.names = FALSE,
                     quote = FALSE, na = "")

  invisible(file)
}
