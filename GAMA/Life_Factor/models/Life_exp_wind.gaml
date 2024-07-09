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
	file cbd_windparticle <- file ("../includes/GIS/microclimate/Wind/wind_startpoint.shp");
	file cbd_wind_bounds <- file ("../includes/GIS/microclimate/Wind/wind_startbounds.shp");	
	
	geometry shape <- envelope(shape_file_bounds);
	
	bool show_landuse<-true;
	bool show_heritage<-false;
	bool show_tree<-false;
	bool show_green<-false;
	bool show_water<-false;
	bool show_fox<-false;
	bool show_bird<-false;
	bool show_avgwindspeed<-true;
	bool show_avgwinddirection<-true;
	bool show_windborder<-true;
	
	
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
			
			/*if (mydepth<200){
				do die;
			}*/
			
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
			//People agents are placed randomly among the free space
			
			location <- any_location_in(free_space);
			//target_loc <-  target_point;
			target_loc<-{location.x,world.shape.height};
			shape<-circle(size);
		} 		 	
		create water from: cbd_water_flow;
		create heritage_building from: cbd_buildings_heritage with: [type::string(read ("HERIT_OBJ"))] ;
		create trees from: cbd_trees ;
		create green from:cbd_green;
		create wastewater from: cbd_buildings;
		create fox number:100;
		create bird number:100{
			green tmp_green<-one_of(green);
			location<-any_location_in(one_of(tmp_green));
			my_home<-tmp_green;
		}
		
		write "building: " + length(building);
		write "windy_building: " + length(windy_building);
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
		write name + " is arrived";
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
		write "wtf do you want?????'";
		write "I domn4t fuckingh know ;y speed" + muCurrentSpeedZone;
		wind_avgspeed tmp<-wind_avgspeed first_with(each overlaps self.shape);
		write "now I know that my speed " + tmp.mySpeed;
		speed<-float(tmp.mySpeed);
		
		
		
	}	
	aspect base {
		draw pyramid(size) color: color;
		draw sphere(size/3) at: {location.x,location.y,size*0.75} color: color;
	}
	
	aspect abstract {
		//draw rectangle(5,10) rotate:heading;
		draw triangle(50) rotate:heading+90 color:#darkblue;
		//draw sphere(size*10) color: color;
	}
}

species global_wind_particle{
	
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
		draw shape color:#pink depth:mydepth;
	}	
}
species water {
	aspect base {
		draw shape color:#blue width:2;	
    }
}
species heritage_building {
	string type;
	int mydepth;
		
	aspect base {
		if (type="N"){
			color<-#black;
		}
		draw shape color:color;		
	}
}
species trees {
	aspect base {
		draw sphere(3) color:#green;
	}
}
species green{
	aspect base {
		draw shape color:#green;
	}
}
species wastewater{
	aspect base {
		draw circle(2) color:#red ;
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
species fox skills:[moving]{
	
	aspect base{
		draw triangle(5) rotate:heading+90 color:#brown;
	}
	reflex move{
		do wander speed:1.0;
	}
}
species bird skills:[moving]{
	green my_home;
	
	reflex move{
		do wander bounds:my_home.shape;
	}
	aspect base{
		draw triangle(5) rotate:heading+90 color:#white;
	}
}

experiment life type: gui {		
	output synchronized:true{
		display city_display type:3d {
			species border aspect:base ;
			species building aspect:base visible:show_landuse;
			species water aspect:base visible:show_water;
			species heritage_building aspect:base visible:show_heritage;
			species trees aspect:base visible:show_tree;
			species green aspect:base visible:show_green;
			species fox aspect:base  visible:show_fox;
			species bird aspect:base  visible:show_bird;
			species wind_avgspeed aspect:base  visible:show_avgwindspeed;
			species wind_avgdirection aspect:base  visible:show_avgwinddirection;
			species windborder aspect:base  visible:show_windborder;
			
			species windy_building aspect:base;
			species windparticle aspect:abstract;
		
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