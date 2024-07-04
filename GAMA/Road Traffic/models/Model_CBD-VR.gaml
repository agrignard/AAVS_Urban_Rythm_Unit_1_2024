model tutorial_gis_city_traffic_model_VR

import "Model_CBD.gaml"

species unity_linker parent: abstract_unity_linker {
	string player_species <- string(unity_player);
	int max_num_players  <- 1;
	int min_num_players  <- 1;
	unity_property up_road;
	unity_property up_building;
	unity_property up_people;
	list<point> init_locations <- define_init_locations();

	list<point> define_init_locations {
		return [any_location_in(one_of(road))];
	}


	init {
		do define_properties;
		do add_background_geometries(road collect (each.shape + 2.0),up_road);
		do add_background_geometries(building,up_road);
	}
	action define_properties {
		unity_aspect road_aspect <- geometry_aspect(0.5,#black,precision);
		up_road <- geometry_properties("road","",road_aspect,#no_interaction,false);
		unity_properties << up_road;


		unity_aspect building_aspect <- geometry_aspect(10.0,#gray,precision);
		up_building <- geometry_properties("building","",building_aspect,#no_interaction,false);
		unity_properties << up_building;


		unity_aspect people_aspect <- prefab_aspect("Prefabs/Visual Prefabs/City/Vehicles/Car",30.0,1.1,-1.0,-90.0,precision);
		up_people <- geometry_properties("people","",people_aspect,#no_interaction,false);
		unity_properties << up_people;


	}
	reflex send_geometries {
		do add_geometries_to_send(people,up_people);
	}
}

species unity_player parent: abstract_unity_player{
	float player_size <- 20.0;
	rgb color <- #red;
	float cone_distance <- 10.0 * player_size;
	float cone_amplitude <- 90.0;
	float player_rotation <- 90.0;
	bool to_display <- true;
	aspect default {
		if to_display {
			if selected {
				 draw circle(player_size) at: location + {0, 0, 4.9} color: rgb(#blue, 0.5);
			}
			draw circle(player_size/2.0) at: location + {0, 0, 5} color: color ;
			draw player_perception_cone() color: rgb(color, 0.5);
		}
	}
}

experiment vr_xp parent:road_traffic autorun: false type: unity {
	float minimum_cycle_duration <- 0.1;
	string unity_linker_species <- string(unity_linker);
	list<string> displays_to_hide <- ["city_display"];
	float t_ref;

	action create_player(string id) {
		ask unity_linker {
			do create_player(id);
		}
	}

	action remove_player(string id_input) {
		if (not empty(unity_player)) {
			ask first(unity_player where (each.name = id_input)) {
				do die;
			}
		}
	}

	output {
		 display city_display_VR parent:city_display{
			 species unity_player;
			 event #mouse_down{
				 float t <- gama.machine_time;
				 if (t - t_ref) > 500 {
					 ask unity_linker {
						 move_player_event <- true;
					 }
					 t_ref <- t;
				 }
			 }
		 }
	}
}
