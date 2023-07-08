/**
 * An object that contains all overmap objects on a target level.
 */

/datum/overmap_level
	var/identifier = 0
	var/name = "Unnamed Map"
	/// List of physics objects active on this level.
	var/list/physics_objects = list()
	// Create a unique identifier so that we can be referenced by the UI calls
	// without worry for conflicts.
	var/static/created_levels = 0
	var/datum/star_system/current_system = null
	var/datum/overmap_level/parent = null
	var/datum/vec5/position = null

/datum/overmap_level/debug_level
	name = "Debug Level"

/datum/overmap_level/New(name)
	. = ..()
	identifier = ++created_levels
	if(name)
		src.name = name
	SSJSOvermap.overmap_levels += src

/datum/overmap_level/New(name, datum/star_system/S)
	. = ..()
	current_system = S

/datum/overmap_level/Destroy(force, ...)
	// This is here to prevent hard-dels in the case that
	// we delete the debug level. This will result in several other errors
	// as the debug level is not nullable.
	if (SSJSOvermap.debug_level == src)
		SSJSOvermap.debug_level = null
	// Identify all self references and remove them
	for (var/datum/overmap/contained in physics_objects)
		qdel(contained)
	physics_objects = null
	SSJSOvermap.overmap_levels -= src
	return ..()

/datum/overmap_level/proc/send_sound(datum/overmap/OM, sound, loop=FALSE, message=null, channel=null, ignore_self=TRUE)
	SEND_SIGNAL(src, COMSIG_JS_OVERMAP_SYSTEM_RELAY_SOUND, OM, sound, message, loop, channel, ignore_self)
/**
	Register "target" with the overmap.
	Pass in a newly created overmap object, and it will be tracked.
*/
/datum/overmap_level/proc/register(datum/overmap/target)
	physics_objects += target
	//TODO: added this.
	target.map = src
	target.position.z = identifier
	target.RegisterSignal(src, COMSIG_JS_OVERMAP_SYSTEM_RELAY_SOUND, (/datum/overmap/proc/on_sound_relayed))

	SEND_SIGNAL(SSJSOvermap, COMSIG_JS_OVERMAP_UPDATE, target)

/**
	Register a list of overmaps as one processing "batch".
	This means the UI is only marked dirty ONCE, as the ships are pushed in.
*/
/datum/overmap_level/proc/register_batch(list/targets)
	if(!targets)
		return
	for(var/datum/overmap/O in targets)
		physics_objects += O
	SEND_SIGNAL(SSJSOvermap, COMSIG_JS_OVERMAP_UPDATE, targets[1])

/datum/overmap_level/proc/unregister(datum/overmap/target)
	SEND_SIGNAL(SSJSOvermap, COMSIG_JS_OVERMAP_UPDATE, target)
	physics_objects -= target
	STOP_PROCESSING(SSJSOvermap, target)
	return

/datum/overmap_level/proc/transfer_to(datum/overmap/target, datum/overmap_level/other)
	if(!other)
		CRASH("Null level passed into transfer_to")
	target.UnregisterSignal(src, COMSIG_JS_OVERMAP_SYSTEM_RELAY_SOUND)

	physics_objects -= target
	SEND_SIGNAL(SSJSOvermap, COMSIG_JS_OVERMAP_UPDATE, target)
	other.register(target)
	target.position.z = other.identifier
