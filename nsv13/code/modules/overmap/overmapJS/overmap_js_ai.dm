/**

	Author: Kmc2000

	Js overmap AI behaviours. Uses GOAP as a basis.

*/

//Fires more often than SSobj, but less often than fast process.
PROCESSING_SUBSYSTEM_DEF(overmap_js_ai)
	name = "Overmap JS AI"
	//Recheck plans / behaviours every half second. Not great, not terrible..
	wait = 0.5 SECONDS
	stat_tag = "JSAI"
	//priority = FIRE_PRIORITY_NPC
	flags = SS_BACKGROUND|SS_POST_FIRE_TIMING

#define GOAP_PRECONDITION_NONE "NONE"
#define GOAP_PRECONDITION_HAS_ANY_TARGET "HAS_ANY_TARGET"
#define GOAP_PRECONDITION_ENGAGING_TARGET "ENGAGING_TARGET"
#define GOAP_PRECONDITION_PATROLLING "PATROLLING"
#define GOAP_PRECONDITION_FLEEING "FLEEING"
#define GOAP_PRECONDITION_ESCORTING "ESCORTING"
#define GOAP_PRECONDITION_FTL_JUMPING "FTL_JUMPING"
#define GOAP_PRECONDITION_AT_SYSTEM_EDGE "AT_SYSTEM_EDGE"

#define GOAP_DEFAULT_STATE list(GOAP_PRECONDITION_HAS_ANY_TARGET = FALSE,\
	GOAP_PRECONDITION_ENGAGING_TARGET = FALSE,\
	GOAP_PRECONDITION_PATROLLING = FALSE,\
	GOAP_PRECONDITION_FLEEING = FALSE,\
	GOAP_PRECONDITION_ESCORTING = FALSE,\
	GOAP_PRECONDITION_FTL_JUMPING = FALSE,\
	GOAP_PRECONDITION_AT_SYSTEM_EDGE = FALSE,\
)

/**
	We are figuring out what goal we want to perform.
*/
#define GOAP_STATE_IDLE 0
/**
	We are required to move to a location before we can act.
*/
#define GOAP_STATE_MOVE_TO 1
/**
	Move to the next action.
*/
#define GOAP_STATE_PERFORM_ACTION 2

#define GOAP_COST_SMALL 2
#define GOAP_COST_MEDIUM 4
#define GOAP_COST_HIGH 8

#define GOAP_GOAL_CATEGORY_GENERAL 1
#define GOAP_GOAL_CATEGORY_COMBAT 2
#define GOAP_GOAL_CATEGORY_MINING 3

/datum/goap_action
	var/name = "None"
	/**
		The cost of this action. Higher = less likely to perform.
		Actions that are preconditions for other actions should fire first.
	*/
	var/cost = 2

	/**
		Precondition to enter this action.
		Dictionary of preconditions
	*/
	var/list/preconditions = list()
	/**
		Effect that is achieved by this state.
	*/
	var/list/effects = list()

	/**
		If the action has a range requirement to target, we must move to the target first.
	*/
	var/range_requirement = 0 KM

	//Node stuff.
	var/datum/goap_action/parent = null

	var/list/state = list()

	/**
		What category does this goal fall under?
		Agents can subscribe to multiple categories.
	*/
	var/category = GOAP_GOAL_CATEGORY_GENERAL

/**
	Reset any vars and state before planning happens again.
*/
/datum/goap_action/proc/reset(datum/component/overmap_ai_agent/agent)
	return

/datum/goap_action/proc/is_in_range(datum/component/overmap_ai_agent/us, datum/component/overmap_ai_agent/them)
	if(range_requirement <= 0 || them == null)
		return TRUE
	//Do your action range checks here...
	return us.get_distance_to(them) <= range_requirement

/**
	Is the action completed?
*/
/datum/goap_action/proc/is_complete(datum/component/overmap_ai_agent/agent)
	return TRUE

/**
	Check any procedural / world requirements for your action here.
	IE: For finding targets.. could be: "are there any targets in the world?"
*/
/datum/goap_action/proc/check_procedural_state(datum/component/overmap_ai_agent/agent)
	return TRUE
/**
	Add any extra checks to ensure that this action is possible, such as with movement.. "do we have engines?"
*/
/datum/goap_action/proc/can_run(list/state)
	for(var/K in preconditions)
		/**
		state:
			no_target = TRUE
		preconditions:
			no_target = FALSE
		state[K] == TRUE, preconditions[K] == FALSE

		state:

		preconditions:
			no_target = FALSE
		state[K] == FALSE, preconditions[K] == FALSE

		state:
			no_target = FALSE
		preconditions:
			no_target = TRUE
		state[K] == FALSE, preconditions[K] == FALSE

		*/
		//TODO: can always do something involving find.. but got too complex!
		//default state is everything false, for now!
		if(state[K] != preconditions[K])
			return FALSE
	return TRUE

/**
	Apply our effects to the state passed in.
	Used to calculate what will happen to the state of the agent after they perform this action.
*/
/datum/goap_action/proc/apply_effects(list/state)
	var/list/ret = state.Copy()
	for(var/K in effects)
		ret[K] = effects[K]
	return ret

//If you need to set anything up before the action is performed, do so here.
/datum/goap_action/proc/pre_perform(datum/component/overmap_ai_agent/agent)
	return TRUE

/**
	Perform the action, once all state requirements are met.
*/
/datum/goap_action/proc/perform(datum/component/overmap_ai_agent/agent)
	for(var/K in effects)
		agent.state[K] = effects[K]
	return TRUE

/datum/goap_planner
	var/list/available_actions = list()
	var/list/action_categories = list()

/datum/goap_planner/New(list/action_categories)
	src.action_categories = action_categories
	for(var/T in subtypesof(/datum/goap_action))
		var/datum/goap_action/G = new T()
		if(!action_categories[G.category])
			qdel(G)
			continue
		available_actions += G

/datum/goap_planner/proc/goal_state_reached(list/state, list/goal)
	for(var/K in goal)
		if(!state[K] || goal[K] != state[K])
			return FALSE
	return TRUE

/datum/goap_planner/proc/build_graph(datum/goap_action/parent, list/usable_actions, list/leaves, list/goal_state)
	var/found_any_path = FALSE
	//Check all usable actions.
	for(var/datum/goap_action/GA in usable_actions)
		//Can we run this action using the last state?
		if(GA.can_run(parent.state))
			var/list/state = GA.apply_effects(parent.state)
			var/datum/goap_action/leaf = new GA.type()
			leaf.cost = parent.cost + GA.cost
			leaf.parent = parent
			leaf.state = state
			if(goal_state_reached(state, goal_state))
				//We found a path. Add it to the possible solutions.
				leaves += leaf
				found_any_path = TRUE
				break
			//Not found a solution just yet, test all remaining actions and branch the tree out.
			var/list/actions_subset = action_subset(usable_actions, GA)
			if(!found_any_path)
				found_any_path = build_graph(leaf, actions_subset, leaves, goal_state)

	return found_any_path

/datum/goap_planner/proc/action_subset(list/actions, datum/goap_action/to_purge)
	RETURN_TYPE(/list)
	var/list/ret = actions.Copy()
	for(var/datum/goap_action/GA in actions)
		if(GA.type == to_purge.type)
			ret -= GA
	return ret

/datum/goap_planner/proc/plan(datum/component/overmap_ai_agent/agent, list/goal_state)
	//Reset agent's current state.
	agent.reset()
	var/list/queue = list()
	var/list/usable_actions = list()
	for(var/datum/goap_action/GA as() in available_actions)
		GA.reset()
		if(GA.check_procedural_state(agent))
			usable_actions += GA
	var/datum/goap_action/root = new /datum/goap_action()
	root.state = agent.state
	var/list/leaves = list()

	if(!build_graph(root, usable_actions, leaves, goal_state))
		//message_admins("Unable to reach GOAP goal state!!")
		return list()
	/*
		Now we have our leaves, we find the cheapest terminal outcome that we possibly can.
		The cheapest terminal state is the best, shortest path. There are multiple ways to skin this cat!
	*/
	var/datum/goap_action/cheapest = null
	for(var/datum/goap_action/leaf in leaves)
		if(cheapest == null || leaf.cost < cheapest.cost)
			cheapest = leaf
	//Traverse the tree in reverse order, from the cheapest goal.
	var/datum/goap_action/node = cheapest
	while(node != null)
		//Do not include fake root node.
		if(node.parent != null)
			queue += node
		node = node.parent
	return reverseList(queue)

#define AI_ORDERS_SEARCH_AND_DESTROY "search_and_destroy"
#define AI_ORDERS_PATROL_SYSTEM "patrol_system"
#define AI_ORDERS_PATROL_LOCAL "patrol_local_grid"
#define AI_ORDERS_ESCORT "escort"
#define AI_ORDERS_FLEE "flee"
#define AI_ORDERS_RESPOND_TO_DISTRESS_CALL "answer_distress_call"
#define AI_ORDERS_SEND_DISTRESS_CALL "send_distress_call"
#define AI_ORDERS_MINE "mine_asteroids"

/datum/component/overmap_ai_agent
	var/datum/overmap/holder = null
	var/datum/overmap/target = null
	var/GOAP_state = GOAP_STATE_IDLE
	var/list/targets = list()
	var/list/state = GOAP_DEFAULT_STATE
	var/datum/goap_planner/planner = null
	var/list/goal_state = list(
		GOAP_PRECONDITION_HAS_ANY_TARGET = TRUE,
		GOAP_PRECONDITION_ENGAGING_TARGET = TRUE
	)
	var/list/secondary_goal_state = list(
		GOAP_PRECONDITION_PATROLLING = TRUE
	)
	var/list/action_categories = list(
		GOAP_GOAL_CATEGORY_GENERAL = TRUE,
		GOAP_GOAL_CATEGORY_COMBAT = TRUE
	)
	var/list/action_plan = list()
	var/orders = AI_ORDERS_SEARCH_AND_DESTROY
	var/last_orders = AI_ORDERS_SEARCH_AND_DESTROY
	var/base_standing_orders = AI_ORDERS_SEARCH_AND_DESTROY

/**
	AI behaviour for a ship that attempts to mine minerals in the system it's in.
*/
/datum/component/overmap_ai_agent/miner
	base_standing_orders = AI_ORDERS_MINE

/**
	AI behaviour for a ship that finds a VIP target, and protects it.
*/
/datum/component/overmap_ai_agent/escort
	base_standing_orders = AI_ORDERS_ESCORT
	//Fallback: Just find anything to escort, don't bother with combat...
	secondary_goal_state = list(
		GOAP_PRECONDITION_ESCORTING = TRUE
	)


/datum/component/overmap_ai_agent/proc/reset()
	state = GOAP_DEFAULT_STATE
	targets = list()
	target = null

/datum/component/overmap_ai_agent/proc/get_distance_to(datum/overmap/other)
	return holder.get_distance_to(other)

/datum/component/overmap_ai_agent/Initialize()
	src.holder = parent
	planner = new /datum/goap_planner(src.action_categories)
	START_PROCESSING(SSovermap_js_ai, src)

/datum/component/overmap_ai_agent/Destroy(force, silent)
	STOP_PROCESSING(SSovermap_js_ai, src)
	. = ..()

/**
	Make decisions about what our goals are going to be, based on how the ship is doing.
	This will change per agent, so you'll want to override this one!

*/
/datum/component/overmap_ai_agent/proc/get_standing_orders()
	//First things first.. fight or flight?
	var/in_combat = holder.last_combat_entered > 0 && (world.time <= holder.last_combat_entered + 1 MINUTES)
	//Flight:
	if(holder.integrity <= holder.max_integrity / 3)
		//TODO: Can add frustration stat, and if high enough, go for kamikaze!
		//With kamikaze, the ship would detonate its own reactor when near enough to the target.
		//Would also have to check we HAVE a target.

		//TODO: Escorts should never attempt to flee.
		//We can also add personalities to AIs to determine if they'll run, or be crazy and stick it until the end.

		//Only bother to flee if we were recently in combat. Otherwise, we can relax.
		//If combat occurred 10 seconds ago or less, we flee. Otherwise, we can do our thing.
		if(in_combat)
			orders = AI_ORDERS_FLEE
			return
		//TODO: If we are done fleeing, and haven't been in combat for a bit, look for a shipyard to repair at.

	//Fight:
	//If we were recently attacked, fight back!
	if(in_combat)
		orders = AI_ORDERS_SEARCH_AND_DESTROY
		return

	//Otherwise, if we don't need to flee, and we don't have to fight back, continue our normal behaviour pattern.
	//IE: for a miner, this would be mining rocks.
	orders = base_standing_orders
	//TODO: Add any more complicated orders and conditions here, should you need them!

/**
	Calculate your agent's current goal based on its surroundings.
	For example, if we're super low on health, and inside a subgrid, we may want to flee!
*/
/datum/component/overmap_ai_agent/proc/calculate_goal_state()
	switch(orders)
		if(AI_ORDERS_SEARCH_AND_DESTROY)
			goal_state = list(
				GOAP_PRECONDITION_HAS_ANY_TARGET = TRUE,
				GOAP_PRECONDITION_ENGAGING_TARGET = TRUE
			)
			return
		if(AI_ORDERS_FLEE)
			//We want to be fleeing, AND FTLing away from dodge.
			//TODO: Escorts should NOT do this.
			goal_state = list(
				GOAP_PRECONDITION_FLEEING = TRUE,
				GOAP_PRECONDITION_FTL_JUMPING = TRUE
			)
		if(AI_ORDERS_ESCORT)
			//We ideally want to be escorting, AND fighting off enemies.
			//Our fallback is just to escort.
			goal_state = list(
				GOAP_PRECONDITION_ESCORTING = TRUE,
				GOAP_PRECONDITION_HAS_ANY_TARGET = TRUE,
				GOAP_PRECONDITION_ENGAGING_TARGET = TRUE
			)
	//TODO: Add abandonment! If the goal state changes, drop our current actions and start the new one!

/datum/component/overmap_ai_agent/process()
	get_standing_orders()
	calculate_goal_state()
	var/datum/goap_action/current_state = null
	//If we have an action plan, use it.
	//EQUALLY SO, if we are abandoning our goal, go back to idle and get new orders!
	if(orders != last_orders)
		//Abandon!
		to_chat(world, "Abandon orders")
		GOAP_state = GOAP_STATE_IDLE
	else
		if(action_plan && action_plan.len)
			current_state = action_plan[1]
		else
			GOAP_state = GOAP_STATE_IDLE
	switch(GOAP_state)
		if(GOAP_STATE_IDLE)
			action_plan = planner.plan(src, goal_state)
			//We could not find a goal. Resort to the fallback state for our agent (usually patrol.)
			if(!action_plan?.len)
				action_plan = planner.plan(src, secondary_goal_state)
			to_chat(world, "New plan...")

			//We are ready to perform actions.
			GOAP_state = GOAP_STATE_PERFORM_ACTION
			last_orders = orders
			return
		if(GOAP_STATE_PERFORM_ACTION)
			current_state.pre_perform(src)
			//Out of range for next action, need to get closer...
			if(target && !current_state.is_in_range(src, target))
				GOAP_state = GOAP_STATE_MOVE_TO
				return
			to_chat(world, "Action: [current_state.name]")
			current_state.perform(src)
			if(target && !current_state.is_in_range(src, target))
				GOAP_state = GOAP_STATE_MOVE_TO
				return
			if(current_state.is_complete(src))
				action_plan -= current_state
			return
		if(GOAP_STATE_MOVE_TO)
			if(target && !current_state.is_in_range(src, target))
				//to_chat(world, "Action: Move towards target...")
				//Move towards target...
				//TODO: Really need a proper physics based nav system, this one sucks!
				//AIs can cheat and use IAS for now...
				//holder.inertial_dampeners = TRUE
				holder.move_towards(target)
			GOAP_state = GOAP_STATE_PERFORM_ACTION
			return

/datum/overmap/proc/point_towards(datum/vec5/position)
	if(!position)
		return
	src.position.angle = get_angle_to_pos(position)

//Move towards a position using RCS thrusters.
/datum/overmap/proc/move_towards(datum/overmap/target)
	//Point towards the target first to make sure our angle is correct.
	if(istype(target, /datum/vec5))
		point_towards(target)
	else
		point_towards(target.position)
	//Then apply the thrust we need.
	var/dx = cos(position.angle) * thruster_power
	var/dy = sin(position.angle) * thruster_power
	position.velocity.x += dx
	position.velocity.y += dy
	SEND_SIGNAL(SSJSOvermap, COMSIG_JS_OVERMAP_UPDATE, src)
