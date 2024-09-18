/**
* Name: Life
* Based on the internal empty template. 
* Author: arno
* Tags: 
*/


model Life_Wind

import "./parameters.gaml"

/* Insert your model definition here */

global{
	file cbd_wind_avgspeed <- file("../includes/GIS/microclimate/Wind/wind_avgspeed_2.shp");
	file cbd_wind_direction <- file("../includes/GIS/microclimate/Wind/wind_directionanchors.shp");
	file cbd_windpoint <- file ("../includes/GIS/microclimate/Wind/wind_points.shp");
	file cbd_wind_bounds <- file ("../includes/GIS/microclimate/Wind/wind_startbounds.shp");
	file cbd_wind_tunnel <- file ("../includes/GIS/microclimate/Wind/cdb_wind_tunnel.shp");
	
	bool show_avgwindspeed<-false;
	bool show_avgwinddirection<-false;
	bool show_windborder<-false;
	bool show_global_wind_flow<-false;
	bool show_global_wind_point<-false;
	bool show_windy_building<-false;
	bool show_local_wind_particle<-false;	
	
	
	bool local_wind_model<-false;
	int maximal_turn <- 90; //in degree
	int cohesion_factor <- 10;
	//Size of the windparticle
	float windparticle_size <- 0.1;
	//Space without buildings
	geometry free_space;
	//Number of windparticle agent
	int nb_windparticle <- 200;
	//Point to evacuate
	point target_point <- {shape.width/2, shape.height};
	
	init{
		do initWindModel(cbd_buildings);
	}
	
	
	reflex create_flow{
		create global_wind_flow{
			global_wind_point tmpSource<-one_of(global_wind_point where (each.type = "Source"));
			location <- tmpSource.location;
			target <- one_of(global_wind_point where (each.type = "Target"  and (each.line_id=tmpSource.line_id)) );		
		}
	}
	
	reflex updatelocaWind when:(length(windparticle)<nb_windparticle and local_wind_model=true){
		create windparticle{
			location <- any_location_in(free_space);
			target_loc<-{location.x,world.shape.height};
			shape<-circle(size);
		} 
	}
	
	action initFreeSpace{
			free_space <- copy(shape);
			//Creation of the buildinds
			ask windy_building{
				//Creation of the free space by removing the shape of the different buildings existing
				free_space <- free_space - (shape + windparticle_size);
			}
			//Simplification of the free_space to remove sharp edges
			free_space <- free_space simplification(1.0);
			
	 } 
	 
	action initWindModel (file _building){
	 	
	 	create wind_avgspeed from: cbd_wind_avgspeed with: [mySpeed:int(read("speed"))] ;
		create wind_avgdirection from: cbd_wind_direction;
		create windborder from:cbd_wind_bounds;
		
		create wind_tunnel_area from:cbd_wind_tunnel; 
		
		create windy_building from: _building with: [depth::int(read ("structur_1"))]{
			if (depth<180){
				//do die;
			}
			if !(bool(wind_tunnel_area overlapping self)){
			  do die;	
			}
		}

		
				
		do initFreeSpace;
		
		if(local_wind_model){
			create windparticle number: nb_windparticle{
				location <- any_location_in(free_space);
				target_loc<-{location.x,world.shape.height};
				shape<-circle(size);
			} 
		}
				 		
		create global_wind_point from:cbd_windpoint with: [type::string(read ("loc_wind"))];
	 }
}


//Species people which move to the evacuation point using the skill moving
species windparticle skills:[moving]{
	wind_avgspeed muCurrentSpeedZone;
	
	//Target point to evacuate
	point target_loc;
	//Speed of the agent
	float speed <- 0.5 + rnd(1000) / 1000;
	//Velocity of the agent
	point velocity <- {0,0};
	//Direction of the agent taking in consideration the maximal turn an agent is able to make
	float heading max: heading + maximal_turn min: heading - maximal_turn;
	
	//Size of the agent
	float size <- windparticle_size; 
	rgb color <- rgb(rnd(255),rnd(255),rnd(255));
		
	//Reflex to kill the agent when it has evacuated the area
	reflex end when: location distance_to target_loc <= 2 * windparticle_size{
		do die;
	}
	//Reflex to compute the velocity of the agent considering the cohesion factor
	reflex follow_goal  {
		velocity <- velocity + ((target_loc - location) / cohesion_factor);
	}
	//Reflex to apply separation when people are too close from each other
	reflex separation {
		point acc <- {0,0};
		ask (windparticle at_distance size)  {
			acc <- acc - (location - myself.location);
		}  
		velocity <- velocity + acc;
	}
	//Reflex to avoid the different obstacles
	reflex avoid { 
		point acc <- {0,0};
		list<windy_building> nearby_obstacles <- (windy_building at_distance windparticle_size);
		loop obs over: nearby_obstacles {
			acc <- acc - (obs.location - location); 
		}
		velocity <- velocity + acc; 
	}
	//Reflex to move the agent considering its location, target and velocity
	reflex move {
		point old_location <- copy(location);
		do goto target: location + velocity ;
		if not(self overlaps free_space ) {
			location <- ((location closest_points_with free_space)[1]);
		}
		velocity <- location - old_location;
	}
	
	reflex updatemySpeed{
		wind_avgspeed tmp<-wind_avgspeed first_with(each overlaps self.shape);
		speed<-float(tmp.mySpeed);
	}	

	aspect abstract {
		if(heading!=90 or heading=0 or heading=180){
		  draw triangle(30) rotate:heading+90 color:model_color["wind"];	
		}	
	}
}

species global_wind_flow skills: [moving]{
	global_wind_point target ;
	reflex move {
		do goto target: target on: wind_avgdirection speed: 30.0;
	}	
	
	aspect base{
		draw rectangle(5,30) rotate:heading+90 color:model_color["global_wind"];
		draw triangle(30) rotate:heading+90 color:model_color["global_wind"];
	}	
}
species global_wind_point {
	string type;
	int line_id;
	
	aspect base{
		draw circle(25) color:(type="Source") ? #blue : #lightblue wireframe:true;
	}	
}

species windy_building{
	int depth;
	aspect base{
		draw shape color:model_color["wind"] depth:0 wireframe:true width:3;
	}	
}

species wind_avgspeed {
	string type;
	int mydepth;
	int mySpeed;
	
	aspect base {
		if (type="0 - 0.1"){
			color<-#black;
			}
		if (type="5.3 - 5.4"){
			color<-#green;
			}
		if (type="5.4 - 5.5"){
			color<-#blue;
			}
		if (type="5.5 - 5.6"){
			color<-#orange;
			}
		if (type="5.6 - 5.7"){
			color<-#white;
			}
			draw shape color:color;
	}
}
species wind_avgdirection {
	string type;
	int mydepth;
		
	aspect base {
		draw shape color:#purple width:0;		
	}
}
species windborder {
	aspect base {
		draw shape color:#blue width:0;
	}
}


species wind_tunnel_area{
	aspect base {
		draw shape color:#blue width:0;
	}	
}


