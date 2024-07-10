/**
* Name: Life
* Based on the internal empty template. 
* Author: arno
* Tags: 
*/


model Life

/* Insert your model definition here */

global{
	file shape_file_bounds <- file("../includes/GIS/cbd_border.shp");
	file cbd_buildings <- file("../includes/GIS/cbd_buildings.shp");
	
    file cbd_blocks <- file("../includes/GIS/cbd_blocks.shp");
	file cbd_water_flow <- file("../includes/GIS/cbd_water_flow.shp");
	file cbd_buildings_heritage <- file("../includes/GIS/cbd_buildings_heritage.shp");
	file cbd_transport_pedestrian <- file("../includes/GIS/cbd_pedestrian_network_custom.shp");
	file cbd_trees <- file("../includes/GIS/cbd_trees.shp");
	file cbd_green <- file("../includes/GIS/cbd_green.shp");
	
	 //Microclimate_wind
	file cbd_wind_avgspeed <- file("../includes/GIS/microclimate/Wind/wind_avgspeed_2.shp");
	file cbd_wind_direction <- file("../includes/GIS/microclimate/Wind/wind_directionanchors.shp");
	file cbd_windpoint <- file ("../includes/GIS/microclimate/Wind/wind_points.shp");
	file cbd_wind_bounds <- file ("../includes/GIS/microclimate/Wind/wind_startbounds.shp");	
	
	geometry shape <- envelope(shape_file_bounds);
	
	bool show_landuse<-true;
	bool show_heritage<-false;
	bool show_tree<-false;
	bool show_green<-false;
	bool show_water<-false;
	bool show_fox<-false;
	bool show_bird<-false;
	bool show_avgwindspeed<-false;
	bool show_avgwinddirection<-true;
	bool show_windborder<-false;
	
	
    int maximal_turn <- 90; //in degree
	int cohesion_factor <- 10;
	//Size of the windparticle
	float windparticle_size <- 2.0;
	//Space without buildings
	geometry free_space;
	//Number of windparticle agent
	int nb_windparticle <- 100;
	//Point to evacuate
	point target_point <- {shape.width/2, shape.height};
	
	init{		
		create border from: shape_file_bounds ;
		create building from: cbd_buildings with: [type::string(read ("predominan"))] ;
		create wind_avgspeed from: cbd_wind_avgspeed with: [mySpeed:int(read("speed"))] ;
		create wind_avgdirection from: cbd_wind_direction;
		create windborder from:cbd_wind_bounds;
		create windy_building from: cbd_buildings with: [mydepth::100] {
			if (mydepth<100){
				//do die;
			}
		}
		ask windy_building{
			if flip(0.95){
				do die;
			}
		}
				
		free_space <- copy(shape);
		//Creation of the buildinds
		ask windy_building{
			//Creation of the free space by removing the shape of the different buildings existing
			free_space <- free_space - (shape + windparticle_size);
		}
		//Simplification of the free_space to remove sharp edges
		free_space <- free_space simplification(1.0);
		
		create windparticle number: nb_windparticle{
			location <- any_location_in(free_space);
			target_loc<-{location.x,world.shape.height};
			shape<-circle(size);
		} 		 		
		create global_wind_point from:cbd_windpoint with: [type::string(read ("loc_wind"))];
	}
	reflex create_flow{
		create global_wind_flow {
			global_wind_point tmpSource<-one_of(global_wind_point where (each.type = "Source"));
			location <- tmpSource.location;
			target <- one_of(global_wind_point where (each.type = "Target"  and (each.line_id=tmpSource.line_id)) );		
		}
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
		list<building> nearby_obstacles <- (building at_distance windparticle_size);
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
	aspect base {
		draw pyramid(size) color: color;
		draw sphere(size/3) at: {location.x,location.y,size*0.75} color: color;
	}
	
	aspect abstract {
		draw triangle(30) rotate:heading+90 color:#lightblue border:#black;
	}
}

species global_wind_flow skills: [moving]{
	global_wind_point target ;
	reflex move {
		do goto target: target on: wind_avgdirection speed: 30.0;
	}	
	
	aspect base{
		draw triangle(50) rotate:heading+90 color:#darkblue;
	}	
}
species global_wind_point {
	string type;
	int line_id;
	
	aspect base{
		draw circle(25) color:(type="Source") ? #blue : #lightblue wireframe:true;
	}	
}

species border {
	aspect base {
		draw shape color:#blue width:2 wireframe:true;
	}
}
species building {
	string type;
	rgb color <- #gray ;
	int mydepth;
		
	aspect base {
		if (type="Commercial Accommodation"){
			color<-#blue;
		}
		draw shape color:color;
	}
}
species windy_building{
	int mydepth;
	aspect base{
		draw shape color:#lightblue depth:mydepth;
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


experiment life type: gui {		
	output synchronized:true{
		display city_display type:3d {
			species border aspect:base ;
			species building aspect:base visible:show_landuse;
			species wind_avgspeed aspect:base  visible:show_avgwindspeed;
			species windborder aspect:base  visible:show_windborder;
			species global_wind_point aspect:base position:{0,0,0.01};
			species global_wind_flow aspect:base position:{0,0,0.01};
			species wind_avgdirection aspect:base  visible:show_avgwinddirection position:{0,0,0.01};
			
			species windy_building aspect:base;
			species windparticle aspect:abstract position:{0,0,0.01};
		
			event "l"  {show_landuse<-!show_landuse;}
			event "h"  {show_heritage<-!show_heritage;}
			event "t"  {show_tree<-!show_tree;}
			event "w"  {show_water<-!show_water;}
			event "f"  {show_fox<-!show_fox;}
			event "b"  {show_bird<-!show_bird;}
			event "g"  {show_green<-!show_green;}
			event "a"  {show_avgwindspeed<-!show_avgwindspeed;}
			event "e"  {show_avgwinddirection<-!show_avgwinddirection;}
			event "d"  {show_windborder<-!show_windborder;}
		}
	}
}