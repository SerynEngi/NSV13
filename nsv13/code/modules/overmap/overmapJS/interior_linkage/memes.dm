/obj/machinery/button/space_horn
	name = "SPACE Horn"
	desc = "According to Rule 112 of the Space Highway Code, horns are only to be used in order to warn another stellar vessel of your presence.\nThat means you should never honk as a greeting, or as an expression of annoyance.\nIn practice though, everyone ignores this."
	var/next_activate = 0
	req_access = list(ACCESS_CAPTAIN)

/obj/machinery/button/space_horn/attack_hand(mob/user)
	. = ..()
	if(next_activate > world.time)
		return
	var/datum/overmap/OM = get_overmap()
	OM.map?.send_sound(src, 'nsv13/sound/effects/ship/horn.ogg', FALSE, channel=CHANNEL_SHIP_FX)//HOOOOOOOOOOOOONK
	next_activate = world.time + 15 SECONDS
