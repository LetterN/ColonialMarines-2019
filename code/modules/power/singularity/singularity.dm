var/global/list/uneatable = list(
	/turf/open/space,
	/obj/effect/overlay,
	/obj/effect/landmark
	)

/obj/machinery/singularity/
	name = "Gravitational Singularity"
	desc = "A Gravitational Singularity."
	icon = 'icons/obj/singularity.dmi'
	icon_state = "singularity_s1"
	anchored = 1
	density = 1
	layer = FLY_LAYER + 1
	luminosity = 6
	unacidable = 1 //Don't comment this out.
	use_power = 0
	var/current_size = STAGE_ONE
	var/allowed_size = STAGE_ONE
	var/contained = 1 //Are we going to move around?
	var/energy = 100 //How strong are we?
	var/dissipate = TRUE //Do we lose energy over time?
	var/dissipate_delay = 10
	var/dissipate_track = 0
	var/dissipate_strength = 1 //How much energy do we lose?
	var/move_self = TRUE //Do we move on our own?
	var/grav_pull = 4 //How many tiles out do we pull?
	var/consume_range = 0 //How many tiles out do we eat
	var/event_chance = 15 //Prob for event each tick
	var/target = null //its target. moves towards the target if it has one
	var/last_failed_movement = 0//Will not move in the same dir if it couldnt before, will help with the getting stuck on fields thing
	var/teleport_del = 0
	var/last_warning
	var/consumedSupermatter = FALSE //If the singularity has eaten a supermatter shard and can go to stage six

/obj/machinery/singularity/New(loc, var/starting_energy = 50, var/temp = 0)
	//CARN: admin-alert for chuckle-fuckery.
	admin_investigate_setup()

	src.energy = starting_energy
	if(temp)
		spawn(temp)
			cdel(src)
	..()
	start_processing()

/obj/machinery/singularity/attack_hand(mob/user as mob)
	consume(user)
	return 1

/obj/machinery/singularity/ex_act(severity)
	switch(severity)
		if(1)
			if(current_size <= STAGE_TWO)
				investigate_log("has been destroyed by a heavy explosion.", "singulo")
				cdel(src)
				return
			else
				energy -= round(((energy+1)/2),1)
		if(2)
			energy -= round(((energy+1)/3),1)
		if(3)
			energy -= round(((energy+1)/4),1)
	return

/obj/machinery/singularity/Bump(atom/A)
	consume(A)
	return

/obj/machinery/singularity/Bumped(atom/A)
	consume(A)
	return

/obj/machinery/singularity/process()
	if(current_size >= STAGE_TWO)
		move()
		pulse()
		if(prob(event_chance))//Chance for it to run a special event TODO:Come up with one or two more that fit
			event()
	eat()
	dissipate()
	check_energy()

	return

/obj/machinery/singularity/attack_ai() //to prevent ais from gibbing themselves when they click on one.
	return

/obj/machinery/singularity/proc/admin_investigate_setup()
	last_warning = world.time
	var/count = locate(/obj/machinery/containment_field) in orange(30, src)
	if(!count)
		message_admins("A singulo has been created without containment fields active ([x],[y],[z])",1)
	investigate_log("was created. [count?"":"<font color='red'>No containment fields were active</font>"]","singulo")

/obj/machinery/singularity/proc/dissipate()
	if(!dissipate)
		return
	if(dissipate_track >= dissipate_delay)
		src.energy -= dissipate_strength
		dissipate_track = 0
	else
		dissipate_track++

/obj/machinery/singularity/proc/expand(force_size = 0)
	var/temp_allowed_size = src.allowed_size
	if(force_size)
		temp_allowed_size = force_size
	if(temp_allowed_size >= STAGE_SIX && !consumedSupermatter)
		temp_allowed_size = STAGE_FIVE
	switch(temp_allowed_size)
		if(STAGE_ONE)
			current_size = STAGE_ONE
			icon = 'icons/obj/singularity.dmi'
			icon_state = "singularity_s1"
			pixel_x = 0
			pixel_y = 0
			grav_pull = 4
			consume_range = 0
			dissipate_delay = 10
			dissipate_track = 0
			dissipate_strength = 1
		if(STAGE_TWO)//1 to 3 does not check for the turfs if you put the gens right next to a 1x1 then its going to eat them
			if((check_turfs_in(1,1))&&(check_turfs_in(2,1))&&(check_turfs_in(4,1))&&(check_turfs_in(8,1)))
				current_size = STAGE_TWO
				icon = 'icons/effects/96x96.dmi'
				icon_state = "singularity_s3"
				pixel_x = -32
				pixel_y = -32
				grav_pull = 6
				consume_range = 1
				dissipate_delay = 5
				dissipate_track = 0
				dissipate_strength = 5
		if(STAGE_THREE)
			if((check_turfs_in(1,2))&&(check_turfs_in(2,2))&&(check_turfs_in(4,2))&&(check_turfs_in(8,2)))
				current_size = STAGE_THREE
				icon = 'icons/effects/160x160.dmi'
				icon_state = "singularity_s5"
				pixel_x = -64
				pixel_y = -64
				grav_pull = 8
				consume_range = 2
				dissipate_delay = 4
				dissipate_track = 0
				dissipate_strength = 20
		if(STAGE_FOUR)
			if((check_turfs_in(1,3))&&(check_turfs_in(2,3))&&(check_turfs_in(4,3))&&(check_turfs_in(8,3)))
				current_size = STAGE_FOUR
				icon = 'icons/effects/224x224.dmi'
				icon_state = "singularity_s7"
				pixel_x = -96
				pixel_y = -96
				grav_pull = 10
				consume_range = 3
				dissipate_delay = 10
				dissipate_track = 0
				dissipate_strength = 10
		if(STAGE_FIVE)//this one also lacks a check for gens because it eats everything
			current_size = STAGE_FIVE
			icon = 'icons/effects/288x288.dmi'
			icon_state = "singularity_s9"
			pixel_x = -128
			pixel_y = -128
			grav_pull = 10
			consume_range = 4
			dissipate = FALSE //It cant go smaller due to e loss
		if(STAGE_SIX) //This only happens if a stage 5 singulo consumes a supermatter shard.
			current_size = STAGE_SIX
			icon = 'icons/effects/352x352.dmi'
			icon_state = "singularity_s11"
			pixel_x = -160
			pixel_y = -160
			grav_pull = 15
			consume_range = 5
			dissipate = FALSE
	if(current_size == allowed_size)
		investigate_log("<font color='red'>grew to size [current_size]</font>","singulo")
		return 1
	else if(current_size < (--temp_allowed_size))
		expand(temp_allowed_size)
	else
		return 0

/obj/machinery/singularity/proc/check_energy()
	if(energy <= 0)
		investigate_log("collapsed.", "singulo")
		cdel(src)
		return 0
	switch(energy)//Some of these numbers might need to be changed up later -Mport
		if(1 to 199)
			allowed_size = STAGE_ONE
		if(200 to 499)
			allowed_size = STAGE_TWO
		if(500 to 999)
			allowed_size = STAGE_THREE
		if(1000 to 1999)
			allowed_size = STAGE_FOUR
		if(2000 to INFINITY)
			if(energy >= 3000 && consumedSupermatter)
				allowed_size = STAGE_SIX
			else
				allowed_size = STAGE_FIVE
	if(current_size != allowed_size)
		expand()
	return 1

/obj/machinery/singularity/proc/eat()
	set background = 1
	// Let's just make this one loop.
	for(var/atom/X in orange(grav_pull,src))
		var/dist = get_dist(X, src)
		// Movable atoms only
		if(dist > consume_range && istype(X, /atom/movable))
			if(is_type_in_list(X, uneatable))	continue
			if(((X) &&(!X:anchored) && (!istype(X,/mob/living/carbon/human)))|| (src.current_size >= 9))
				step_towards(X,src)
			else if(istype(X,/mob/living/carbon/human))
				var/mob/living/carbon/human/H = X
				if(istype(H.shoes,/obj/item/clothing/shoes/magboots))
					var/obj/item/clothing/shoes/magboots/M = H.shoes
					if(M.magpulse)
						continue
				step_towards(H,src)
		// Turf and movable atoms
		else if(dist <= consume_range && (isturf(X) || istype(X, /atom/movable)))
			consume(X)
	return

/obj/machinery/singularity/proc/consume(atom/A)
	var/gain = 0
	if(is_type_in_list(A, uneatable))
		return 0
	if(istype(A,/mob/living))//Mobs get gibbed
		gain = 20
		if(istype(A,/mob/living/carbon/human))
			var/mob/living/carbon/human/H = A
			if(H.mind)
				if((H.mind.assigned_role == "Station Engineer") || (H.mind.assigned_role == "Chief Engineer") )
					gain = 100

				if(H.mind.assigned_role == "Clown")
					gain = rand(-300, 300) // HONK

		spawn()
			A:gib()
		sleep(1)

	if(istype(A, /obj/machinery/power/supermatter) && !consumedSupermatter) // YOU'RE ALL FUCKED
		desc = "[initial(desc)] It glows fiercely with inner fire."
		name = "supermatter-charged [initial(name)]"
		consumedSupermatter = TRUE
		luminosity = 10

	if(istype(A,/obj/))
		if(istype(A,/obj/item/storage/backpack/holding))
			var/dist = max((current_size - 2),1)
			explosion(src.loc,(dist),(dist*2),(dist*4))
			return

		if(istype(A, /obj/machinery/singularity))//Welp now you did it
			var/obj/machinery/singularity/S = A
			src.energy += (S.energy/2)//Absorb most of it
			cdel(S)
			var/dist = max((current_size - 2),1)
			explosion(src.loc,(dist),(dist*2),(dist*4))
			return//Quits here, the obj should be gone, hell we might be

		if((teleport_del) && (!istype(A, /obj/machinery)))//Going to see if it does not lag less to tele items over to Z 2
			var/obj/O = A
			O.x = 2
			O.y = 2
			O.z = 2
		else
			A.ex_act(1.0)
			if(A)
				cdel(A)
		gain = 2
	if(isturf(A))
		var/turf/T = A
		if(T.intact_tile)
			for(var/obj/O in T.contents)
				if(O.level != 1)
					continue
				if(O.invisibility == 101)
					src.consume(O)
		T.ChangeTurf(/turf/open/space)
		gain = 2
	src.energy += gain
	return

/obj/machinery/singularity/proc/move(force_move = 0)
	if(!move_self)
		return 0

	var/movement_dir = pick(alldirs - last_failed_movement)

	if(force_move)
		movement_dir = force_move

	if(target && prob(60))
		movement_dir = get_dir(src,target) //moves to a singulo beacon, if there is one

	step(src, movement_dir)

/obj/machinery/singularity/proc/check_turfs_in(direction = 0, step = 0)
	if(!direction)
		return 0
	var/steps = 0
	if(!step)
		switch(current_size)
			if(STAGE_ONE)
				steps = 1
			if(STAGE_TWO)
				steps = 3//Yes this is right
			if(STAGE_THREE)
				steps = 3
			if(STAGE_FOUR)
				steps = 4
			if(STAGE_FIVE)
				steps = 5
	else
		steps = step
	var/list/turfs = list()
	var/turf/T = src.loc
	for(var/i = 1 to steps)
		T = get_step(T,direction)
	if(!isturf(T))
		return 0
	turfs.Add(T)
	var/dir2 = 0
	var/dir3 = 0
	switch(direction)
		if(NORTH||SOUTH)
			dir2 = 4
			dir3 = 8
		if(EAST||WEST)
			dir2 = 1
			dir3 = 2
	var/turf/T2 = T
	for(var/j = 1 to steps)
		T2 = get_step(T2,dir2)
		if(!isturf(T2))
			return 0
		turfs.Add(T2)
	for(var/k = 1 to steps)
		T = get_step(T,dir3)
		if(!isturf(T))
			return 0
		turfs.Add(T)
	for(var/turf/T3 in turfs)
		if(isnull(T3))
			continue
		if(!can_move(T3))
			return 0
	return 1

/obj/machinery/singularity/proc/can_move(turf/T)
	if(!T)
		return 0
	if((locate(/obj/machinery/containment_field) in T)||(locate(/obj/machinery/shieldwall) in T))
		return 0
	else if(locate(/obj/machinery/field_generator) in T)
		var/obj/machinery/field_generator/G = locate(/obj/machinery/field_generator) in T
		if(G && G.active)
			return 0
	else if(locate(/obj/machinery/shieldwallgen) in T)
		var/obj/machinery/shieldwallgen/S = locate(/obj/machinery/shieldwallgen) in T
		if(S && S.active)
			return 0
	return 1

/obj/machinery/singularity/proc/event()
	var/numb = pick(1,2,3,4)
	switch(numb)
		if(1)//EMP
			emp_area()
		if(2)//tox damage all carbon mobs in area
			toxmob()
		if(3)//Stun mobs who lack optic scanners
			mezzer()
		if(4)	 //Sets all nearby mobs on fire
			if(current_size < STAGE_SIX)
				return 0
			combust_mobs()
		else
			return 0
	return 1

/obj/machinery/singularity/proc/combust_mobs()
	for(var/mob/living/carbon/C in orange(20, src))
		C.visible_message("<span class='warning'>[C]'s skin bursts into flame!</span>", \
						  "<span class='userdanger'>You feel an inner fire as your skin bursts into flames!</span>")
		C.adjust_fire_stacks(5)
		C.IgniteMob()
	return

/obj/machinery/singularity/proc/toxmob()
	var/toxrange = 10
	var/toxdamage = 4
	var/radiation = 15
	var/radiationmin = 3
	if (src.energy>200)
		toxdamage = round(((src.energy-150)/50)*4,1)
		radiation = round(((src.energy-150)/50)*5,1)
		radiationmin = round((radiation/5),1)//
	for(var/mob/living/M in view(toxrange, src.loc))
		M.apply_effect(rand(radiationmin,radiation), IRRADIATE)
		toxdamage = (toxdamage - (toxdamage*M.getarmor(null, "rad")))
		M.apply_effect(toxdamage, TOX)

/obj/machinery/singularity/proc/mezzer()
	for(var/mob/living/carbon/M in oviewers(8, src))
		if(isbrain(M)) //Ignore brains
			continue

		if(M.stat == CONSCIOUS)
			if(istype(M,/mob/living/carbon/human))
				var/mob/living/carbon/human/H = M
				if(istype(H.glasses,/obj/item/clothing/glasses/meson))
					to_chat(H, "\blue You look directly into [src], good thing you had your protective eyewear on!")
					return
		to_chat(M, "\red You look directly into [src] and feel weak.")
		M.apply_effect(3, STUN)
		visible_message("<span class='danger'>[M] stares blankly at [src]!</span>")

/obj/machinery/singularity/proc/emp_area()
	empulse(src, 8, 10)
	return

/obj/machinery/singularity/proc/pulse()
	for(var/obj/machinery/power/rad_collector/R in rad_collectors)
		if(get_dist(R, src) <= 15) // Better than using orange(s) every process
			R.receive_pulse(energy)

/obj/machinery/singularity/Dispose()
	SetLuminosity(0)
	. = ..()

/obj/machinery/singularity/wizard //adminbus singulo
	name = "tear in the fabric of reality"
	desc = "This isn't right."
	icon = 'icons/effects/224x224.dmi'
	icon_state = "reality"
	pixel_x = -96
	pixel_y = -96
	dissipate = FALSE
	move_self = FALSE
	consume_range = 3
	grav_pull = 4
	current_size = 4
	allowed_size = 4

/obj/machinery/singularity/wizard/admin_investigate_setup()
	return

/obj/machinery/singularity/wizard/process()
	move()
	eat()
	return