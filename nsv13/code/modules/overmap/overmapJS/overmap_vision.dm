
//TODO: Check if the ship can actually see anything!
/datum/overmap/proc/get_sensor_visible_ships()
	RETURN_TYPE(/list)
	return map?.physics_objects.Copy()

/datum/overmap/proc/get_ships_in_grid()
	RETURN_TYPE(/list)
	return map?.physics_objects.Copy()

/datum/overmap/proc/get_distance_to(datum/overmap/other)
	var/datum/vec5/other_pos = null
	//You can also get distance to a point, not a vector.
	if(istype(other, /datum/vec5))
		other_pos = other
	else
		other_pos = other.position
	var/dx = position.x - other_pos.x;
	var/dy = position.y - other_pos.y;
	return sqrt(dx * dx + dy * dy);

/**
	Can we see a given target?
*/
/datum/overmap/proc/can_see(datum/overmap/OM)
	return get_distance_to(OM) <= base_sensor_range
