#' Calculate stress between plates
#' 
#' @param world A world list; the output of \code{\link{gen_plates}}
#' @param spread How many tiles away from the plate border should stress
#'   start being felt? Defaults to 5.
#' 
#' @return an updated world list, where the map contains a stress column
#' 
#' @export
#' 
calc_stress <- function(world, spread = 5) {
  map_x <- max(world$map$x) 
  map_y <- max(world$map$y)
  pb <- txtProgressBar(min = 0, max = nrow(world$map), style = 3, width = 60)
  counter <- 0
  new_stress <- apply(world$map, 1, function(r) {
    counter <<- counter + 1
    setTxtProgressBar(pb, counter)
    # determine the range of nearby cells
    range_x <- wrapped_range(r["x"], spread, map_x)
    range_y <- wrapped_range(r["y"], spread, map_y)

    # pick the cells that match the x and y parameters
    rows_x <- world$map$x %in% range_x
    rows_y <- world$map$y %in% range_y
    neighbours <- rows_x & rows_y
    # if all neighbours belong to same plate, skip
    if (length(unique(world$map$plate[neighbours])) == 1) {
      return(0)
    # otherwise...
    } else {
      not_r_plate <- neighbours & world$map$plate != r["plate"]
  
      rel_x <- wrapped_distance(r["x"], world$map$x[not_r_plate], map_x)
      rel_y <- wrapped_distance(r["y"], world$map$y[not_r_plate], map_y)

      rel_force_x <- world$map$force_x[not_r_plate] - r["force_x"]
      rel_force_y <- world$map$force_y[not_r_plate] - r["force_y"]
      force <- sqrt(rel_force_x^2 + rel_force_y^2)
      stress <- (rel_x * rel_force_x / force) + (rel_y * rel_force_y / force)
      return(-sum(stress))
    }
  })
  close(pb)
  # plates already have a base level. This adds to that
  # base level.
  world$map$stress <- world$map$stress + new_stress
  return(world)
}

calc_slope <- function(world) {
  map_x <- max(world$map$x) 
  map_y <- max(world$map$y)
  pb <- txtProgressBar(min = 0, max = nrow(world$map), style = 3, width = 60)
  counter <- 0
  world$map$slope <- apply(world$map, 1, function(r) {
    counter <<- counter + 1
    setTxtProgressBar(pb, counter)
    # determine the range of nearby cells
    range_x <- wrapped_range(as.numeric(r["x"]), 1, map_x)
    range_y <- wrapped_range(as.numeric(r["y"]), 1, map_y)

    # pick the cells that match the x and y parameters
    rows_x <- world$map$x %in% range_x
    rows_y <- world$map$y %in% range_y
    neighbours <- world$map[rows_x & rows_y, ]

    slope <- max(neighbours$stress) - min(neighbours$stress)
    return(slope)
  })
  close(pb)
  return(world)
}
