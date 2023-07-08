/**
	Anything that's considered a "ship".
	This will have functionality for subsystems, weapons, etc.
*/
/datum/overmap/ship
	icon = 'nsv13/icons/overmap/nanotrasen/light_cruiser.dmi'
	icon_state = "cruiser-100"
	name = "Space SHIP"
	armour_quadrants = list(
		//North East
		new /datum/armour_quadrant(OVERMAP_ARMOUR_THICKNESS_MEDIUM),
		//North West
		new /datum/armour_quadrant(OVERMAP_ARMOUR_THICKNESS_MEDIUM),
		//South West
		new /datum/armour_quadrant(OVERMAP_ARMOUR_THICKNESS_MEDIUM),
		//South East
		new /datum/armour_quadrant(OVERMAP_ARMOUR_THICKNESS_MEDIUM)
	)
	integrity = OVERMAP_ARMOUR_THICKNESS_MEDIUM
	max_integrity = OVERMAP_ARMOUR_THICKNESS_MEDIUM

/datum/overmap/ship/player
	name = "NSV Rocinante"
	faction = OVERMAP_FACTION_PLAYER
	interior_type = /datum/component/overmap_interior
	role = OVERMAP_ROLE_PRIMARY
	starting_system = "Sol"
	//collision_positions = list(new /matrix/vector(-8,46), new /matrix/vector(-17,33), new /matrix/vector(-25,2), new /matrix/vector(-14,-45), new /matrix/vector(9,-46), new /matrix/vector(22,4), new /matrix/vector(14,36))

/datum/overmap/ship/player/cruiser
	name = "NSV Tycoon"
	faction = OVERMAP_FACTION_PLAYER
	icon = 'nsv13/icons/overmap/nanotrasen/battlecruiser.dmi'
	icon_state = "battlecruiser"
	mass = MASS_MEDIUM_LARGE
	armour_quadrants = list(
		//North East
		new /datum/armour_quadrant(OVERMAP_ARMOUR_THICKNESS_MEDIUM),
		//North West
		new /datum/armour_quadrant(OVERMAP_ARMOUR_THICKNESS_MEDIUM),
		//South West
		new /datum/armour_quadrant(OVERMAP_ARMOUR_THICKNESS_MEDIUM),
		//South East
		new /datum/armour_quadrant(OVERMAP_ARMOUR_THICKNESS_MEDIUM)
	)
	integrity = OVERMAP_ARMOUR_THICKNESS_MEDIUM
	max_integrity = OVERMAP_ARMOUR_THICKNESS_MEDIUM

/datum/overmap/ship/player/cruiser/heavy
	name = "NSV Hammerhead"
	faction = OVERMAP_FACTION_PLAYER
	icon = 'nsv13/icons/overmap/nanotrasen/heavy_cruiser.dmi'
	icon_state = "heavy_cruiser"
	mass = MASS_LARGE
	armour_quadrants = list(
		//North East
		new /datum/armour_quadrant(OVERMAP_ARMOUR_THICKNESS_SUPER_HEAVY),
		//North West
		new /datum/armour_quadrant(OVERMAP_ARMOUR_THICKNESS_SUPER_HEAVY),
		//South West
		new /datum/armour_quadrant(OVERMAP_ARMOUR_THICKNESS_LIGHT),
		//South East
		new /datum/armour_quadrant(OVERMAP_ARMOUR_THICKNESS_LIGHT)
	)
	integrity = OVERMAP_ARMOUR_THICKNESS_SUPER_HEAVY
	max_integrity = OVERMAP_ARMOUR_THICKNESS_SUPER_HEAVY

//Welcome..home
/datum/overmap/ship/player/battleship
	name = "NSV Galactica"
	faction = OVERMAP_FACTION_PLAYER
	icon = 'nsv13/icons/overmap/nanotrasen/Battleship.dmi'
	icon_state = "battleship"
	mass = MASS_MEDIUM_LARGE
	armour_quadrants = list(
		//North East
		new /datum/armour_quadrant(OVERMAP_ARMOUR_THICKNESS_SUPER_HEAVY),
		//North West
		new /datum/armour_quadrant(OVERMAP_ARMOUR_THICKNESS_SUPER_HEAVY),
		//South West
		new /datum/armour_quadrant(OVERMAP_ARMOUR_THICKNESS_SUPER_HEAVY),
		//South East
		new /datum/armour_quadrant(OVERMAP_ARMOUR_THICKNESS_SUPER_HEAVY)
	)
	integrity = OVERMAP_ARMOUR_THICKNESS_SUPER_HEAVY
	max_integrity = OVERMAP_ARMOUR_THICKNESS_SUPER_HEAVY

/datum/overmap/ship/syndicate
	name = "SSV Dumbass"
	faction = OVERMAP_FACTION_SYNDICATE
	icon = 'nsv13/icons/overmap/syndicate/syn_light_cruiser.dmi'
	icon_state = "cruiser"
	mass = MASS_MEDIUM
	armour_quadrants = list(
		//North East
		new /datum/armour_quadrant(OVERMAP_ARMOUR_THICKNESS_MEDIUM),
		//North West
		new /datum/armour_quadrant(OVERMAP_ARMOUR_THICKNESS_MEDIUM),
		//South West
		new /datum/armour_quadrant(OVERMAP_ARMOUR_THICKNESS_MEDIUM),
		//South East
		new /datum/armour_quadrant(OVERMAP_ARMOUR_THICKNESS_MEDIUM)
	)
	ai_type = /datum/component/overmap_ai_agent
	//collision_positions = list(new /matrix/vector(-3,45), new /matrix/vector(-17,29), new /matrix/vector(-22,-12), new /matrix/vector(-11,-45), new /matrix/vector(7,-47), new /matrix/vector(22,-12), new /matrix/vector(9,30))

/datum/overmap/ship/syndicate/frigate
	name = "SSV Peon"
	faction = OVERMAP_FACTION_SYNDICATE
	icon = 'nsv13/icons/overmap/new/syndicate/frigate.dmi'
	icon_state = "mako"
	mass = MASS_SMALL
	armour_quadrants = list(
		//North East
		new /datum/armour_quadrant(OVERMAP_ARMOUR_THICKNESS_LIGHT),
		//North West
		new /datum/armour_quadrant(OVERMAP_ARMOUR_THICKNESS_LIGHT),
		//South West
		new /datum/armour_quadrant(OVERMAP_ARMOUR_THICKNESS_LIGHT),
		//South East
		new /datum/armour_quadrant(OVERMAP_ARMOUR_THICKNESS_LIGHT)
	)

/datum/overmap/ship/syndicate/cruiser
	name = "SSV Dunning-Kreuger"
	faction = OVERMAP_FACTION_SYNDICATE
	icon = 'nsv13/icons/overmap/syndicate/syn_patrol_cruiser.dmi'
	icon_state = "patrol_cruiser-100"
	mass = MASS_LARGE
	integrity = OVERMAP_ARMOUR_THICKNESS_HEAVY
	max_integrity = OVERMAP_ARMOUR_THICKNESS_HEAVY
	armour_quadrants = list(
		//North East
		new /datum/armour_quadrant(OVERMAP_ARMOUR_THICKNESS_HEAVY),
		//North West
		new /datum/armour_quadrant(OVERMAP_ARMOUR_THICKNESS_HEAVY),
		//South West
		new /datum/armour_quadrant(OVERMAP_ARMOUR_THICKNESS_HEAVY),
		//South East
		new /datum/armour_quadrant(OVERMAP_ARMOUR_THICKNESS_HEAVY)
	)

/datum/overmap/ship/syndicate/destroyer
	name = "SSV Dunning-Kreuger"
	faction = OVERMAP_FACTION_SYNDICATE
	icon = 'nsv13/icons/overmap/syndicate/gunboat.dmi'
	icon_state = "gunboat-100"
	mass = MASS_MEDIUM
	integrity = OVERMAP_ARMOUR_THICKNESS_MEDIUM
	max_integrity = OVERMAP_ARMOUR_THICKNESS_MEDIUM
	armour_quadrants = list(
		//North East
		new /datum/armour_quadrant(OVERMAP_ARMOUR_THICKNESS_MEDIUM),
		//North West
		new /datum/armour_quadrant(OVERMAP_ARMOUR_THICKNESS_MEDIUM),
		//South West
		new /datum/armour_quadrant(OVERMAP_ARMOUR_THICKNESS_MEDIUM),
		//South East
		new /datum/armour_quadrant(OVERMAP_ARMOUR_THICKNESS_MEDIUM)
	)
