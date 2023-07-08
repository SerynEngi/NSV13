


/datum/overmap/projectile
	mass = MASS_PROJECTILE
	name = "overmap projectile"
	icon = 'nsv13/icons/obj/projectiles_nsv.dmi'
	icon_state = "pdc"
	base_sensor_range = 0
	//Projectile specific bits...
	var/damage = 10
	/**
		Percentile chance for a bullet to ignore armour entirely and penetrate through.
	*/
	var/armour_penetration_factor = 0
	var/damage_type = OVERMAP_DAMAGE_TYPE_KINETIC_SUBCAPITAL
	var/unstoppable = FALSE
	///Distance this projectile may travel before it's auto-deleted / culled.
	var/range = 1 KM
	var/distance_travelled = 0
	var/speed = 10 //m/s
	var/physical_projectile_type = /obj/item/projectile/bullet
	var/projectile_flags = OVERMAP_PROJECTILE_FLAGS_NONE

/datum/overmap/projectile/slug
	name = "railgun slug"
	icon_state = "railgun"
	damage = 25
	damage_type = OVERMAP_DAMAGE_TYPE_KINETIC_CAPITAL
	range = 25 KM
	unstoppable = TRUE
	speed = 50
/datum/overmap/projectile/shell
	name = "cannon shell"
	icon_state = "mac"
	damage = 50
	damage_type = OVERMAP_DAMAGE_TYPE_KINETIC_CAPITAL
	range = 25 KM
	speed = 25

/datum/overmap/projectile/warhead
	name = "conventional missile"
	icon_state = "torpedo"
	damage = 75
	damage_type = OVERMAP_DAMAGE_TYPE_EXPLOSIVE
	range = 52 KM
	speed = 50
	//Hint to gun batteries that we can shoot down warheads.
	projectile_flags = OVERMAP_PROJECTILE_FLAGS_CAN_BE_SHOT_DOWN

/datum/overmap/projectile/on_move()
	..()
	distance_travelled += position.velocity.ln()
	if(distance_travelled > range)
		qdel(src)

/datum/overmap/projectile/proc/on_hit(datum/overmap/target, angle)
	var/resistance = target.damage_resistances[damage_type]
	//If we have no resistance, OR the bullet rolls for full armour pen...
	//Yep this is definitely how AP works, stupid? I dunno! see take_quadrant_hit too!
	if(!resistance || prob(armour_penetration_factor))
		resistance = 0
	var/amount = abs(damage - (damage * (resistance / 100)))
	//Attempt to absorb the hit into a quadrant. If they block us, our life ends here..
	if(target.take_quadrant_hit(src, amount, angle))
		if(!unstoppable)
			qdel(src)
	//Do we have an interior? If so, let that handle the hit!
	if(target.interior)
		return target.interior.take_damage(src, angle)

	. = target.take_damage(amount, damage_type)
	//Unstoppable projectiles rip straight through everything. IE: railgun slugs. Line 'em up!
	if(!unstoppable)
		qdel(src)

/datum/overmap/proc/get_angle_to(datum/overmap/O)
	return ATAN2((O.position.x - position.x), (O.position.y - position.y))

/datum/overmap/proc/get_angle_to_pos(datum/vec5/O)
	return ATAN2((O.x - position.x), (O.y - position.y))

/datum/overmap/proc/radians(d)
	return (d * PI) / 180;

/// The provided target is the object impacting with src.
/datum/overmap/proc/get_armour_quadrant_for_impact(datum/overmap/O)
	RETURN_TYPE(/datum/armour_quadrant)
	//Process the impact to our armour, normalized.
	//var/shield_angle_hit = SIMPLIFY_DEGREES(get_angle_to(O)) - SIMPLIFY_DEGREES(position.angle-90)
	//var/offset = SIMPLIFY_DEGREES(position.angle)
	//Correct screen angle to actual angle.
	//var/normal = SIMPLIFY_DEGREES(offset - 180)
	//var/shield_angle_hit = SIMPLIFY_DEGREES(get_angle_to(O) - normal)

	//Our angles are flipped. so we do this backwards nonsense.
	// Get the ngle towrds ourselves from the object tht is colliding with us.
	// Bacon maths hack: The angle of the projectile, inverted, is always the collision angle. Just trust him / me.. he showed me on a whiteboard :)
	var/shield_angle_hit = SIMPLIFY_DEGREES((position.angle) - (O.position.angle+90) + 360)

	//to_chat(world, "[shield_angle_hit]")
	//Convert angle of hit into relevent armour segment.
	switch(shield_angle_hit)
		if(0 to 89)
			return armour_quadrants[ARMOUR_QUADRANT_NORTH_EAST]
		if(90 to 179)
			return armour_quadrants[ARMOUR_QUADRANT_NORTH_WEST]
		if(180 to 269)
			return armour_quadrants[ARMOUR_QUADRANT_SOUTH_WEST]
		if(270 to 360)
			return armour_quadrants[ARMOUR_QUADRANT_SOUTH_EAST]
	// Throw an error for investigtive purposes
	CRASH("Invalid shield angle provided inside of get_armour_quadrant_for_impact, got [shield_angle_hit], expected a value between 0 and 360.")

/**
	Attempt to absorb a bullet's damage into the ship's armour quadrants.
	Returns TRUE if the shot was blocked.
*/
/datum/overmap/proc/take_quadrant_hit(datum/overmap/projectile/P, amount, angle)
	//The shot bypassed the armour entirely. This is totes how AP works ;)
	//@Karmic, todo definitely here.. this is stupid(?) I don't know!
	if(!armour_quadrants)
		return FALSE
	var/datum/armour_quadrant/Q = get_armour_quadrant_for_impact(P)
	//If the shot penetrates, absorb half the damage into the plate, and let the shot past.
	if(prob(P.armour_penetration_factor))
		Q?.take_damage(amount/2)
		return FALSE
	return Q && Q.take_damage(amount)

/**
	What happens when an overmap object physically takes damage, from any source.
*/
/datum/overmap/proc/take_damage(amount, damage_type)
	integrity -= amount
	last_combat_entered = world.time
	if(integrity <= 0)
		explode()

/**
	What happens when an enemy ship explodes?
	Physically only possible for overmap vessels WITHOUT interiors.
*/
/datum/overmap/proc/explode()
	qdel(src)

/datum/overmap/proc/bullet_act(datum/overmap/projectile/P, angle)
	SEND_SIGNAL(src, COMSIG_ATOM_BULLET_ACT, P, angle)
	. = P.on_hit(src, angle)

/datum/overmap/proc/ex_act(severity)
