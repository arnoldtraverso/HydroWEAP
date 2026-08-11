#' Funcion de extracción rápida de datos de precipitaciones
#' La función se ejecuta para extrer los datos de preciptiaciones de un
#' formato de datos tipo NetCDF y las lleva a formatos de texto csv
#' delimitado por comas, este fomrato de salida será utlizado para llevalos 
#' datos al modelo hidrológico WEAP 
#' 
#' @param grid Directorio de información de datos en NetCDF
#' @param subs Directorio de archivo '.shp', en general de una cuenca hidrográfica y sus subcvuencas
#' @param cores Número de hilos de proceso, según disponible por procesador 
#'
#' @export
#' @importFrom terra rast vect extract
#' @importFrom utils txtProgressBar setTxtProgressBar

pcp2weap <- function(grid, subs, cores){
  
  cell.numbers <- function(grid, geom){
    spacialcov <- grid
    spacialcov[] <- 1:raster::ncell(grid)
    position_rowcol <- function(i){
      quad1 <- unlist(raster::extract(x = spacialcov, y = geom[i, ], small = TRUE))
    }
    position <- lapply(1:length(geom), position_rowcol)
    return(position)
  }
  
  extract.fast <- function(grid, cells, fun = mean, na.rm = TRUE){
    matrix.r <- t(raster::as.matrix(grid))
    res <- sapply(1:length(cells), function(i){
      value <- matrix.r[cells[[i]]]
      fun(value, na.rm = na.rm)
    })
  }
  
  cell.numbers <- cell.numbers(grid = grid[[1]], geom = subs)
  cl <- parallel::makeCluster(cores)
  
  parallel::clusterEvalQ(cl = cl, expr = c(library(raster)))
  parallel::clusterExport(cl = cl, varlist = c("grid",
                                               "cell.numbers",
                                               "extract.fast"),
                          envir = environment())
  
  # proceso de extraccion
  mean <- parallel::parLapply(cl, c(1:raster::nlayers(grid)), function(z){
    pre <- extract.fast(grid = grid[[z]],
                        cells = cell.numbers,
                        fun = mean,
                        na.rm = TRUE)
    return(pre)
  })
  
  parallel::stopCluster(cl)
  mean <- do.call(rbind, mean)
  return(mean)
}

# ---------------------------------------------------------------------------
# FUNCION: escribir el CSV en formato WEAP
# ---------------------------------------------------------------------------
write_weap_csv <- function(df, file){
  # df debe traer las columnas: Date, Year, Month, Day, <catchments...>
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
}
