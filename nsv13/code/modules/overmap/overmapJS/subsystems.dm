/**
	Return the sensor range for an overmap.

	TODO: Tie this into sensors subsystem!
*/
/datum/overmap/proc/get_sensor_range()
	return base_sensor_range

/datum/overmap/projectile/get_sensor_range()
	return 0
