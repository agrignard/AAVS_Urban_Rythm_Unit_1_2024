/**
* Name: Life
* Based on the internal empty template. 
* Author: arno
* Tags: 
*/


model Life

/* Insert your model definition here */

global{
	//Shapefiles from GIS
	file shape_file_bounds <- file("../includes/GIS/cbd_border.shp");
	file cbd_buildings <- file("../includes/GIS/cbd_buildings.shp");	
	file cbd_buildings_heritage <- file("../includes/GIS/cbd_buildings_heritage.shp");
	file cbd_transport_pedestrian <- file("../includes/GIS/cbd_pedestrian_network_custom.shp");
	file cbd_trees <- file("../includes/GIS/cbd_trees.shp");
	file cbd_green <- file("../includes/GIS/cbd_green.shp");
	
	 //Biodiversity
	file cbd_bird_migration <- file("../includes/GIS/microclimate/Biodiversity/biodiversity_bird_migration.shp");
	file cbd_bird_start <- file("../includes/GIS/microclimate/Biodiversity/biodiversity_bird_entrancepoint.shp");
	file cbd_fox_migration <- file("../includes/GIS/microclimate/Biodiversity/biodiversity_fox_migrationroute.shp");
	file cbd_fox_start <- file("../includes/GIS/microclimate/Biodiversity/biodiversity_fox_migration.shp");
	
	 //Microclimate_wind
	file cbd_wind_avgspeed <- file("../includes/GIS/microclimate/Wind/wind_avgspeed.shp");
	file cbd_wind_direction <- file("../includes/GIS/microclimate/Wind/wind_directionanchors.shp");
	file cbd_windparticle <- file ("../includes/GIS/microclimate/Wind/wind_startpoint.shp");
	file cbd_wind_bounds <- file ("../includes/GIS/microclimate/Wind/wind_startboundary.shp");	
	
	 //Microclimate_water
	file cbd_water_flow <- file("../includes/GIS/cbd_water_flow.shp");
	
	//Shape of the environment
	geometry shape <- envelope(cbd_buildings);
	int maximal_turn <- 90; //in degree
	int cohesion_factor <- 10;
	
	//Size of the windparticles
	float windparticle_size <- 2.0;
	//Space without buildings
	geometry free_space;
	//Number of windparticle agent
	int nb_windparticle <- 100;
	//Point to die
	point target_point <- {shape.height, 0};
	
	//Interaction interface
	bool show_building<-true;
	bool show_heritage<-true;
	bool show_tree<-true;
	bool show_green<-true;
	bool show_water<-true;
	bool show_fox<-true;
	bool show_wind_avgspeed<-true;
	bool show_wind_avgdirection<-true;
	
	init{
		create border from: shape_file_bounds ;
		create building from: cbd_buildings with: [type::string(read ("predominan"))] ;
		create water from: cbd_water_flow;
		create heritage_building from: cbd_buildings_heritage with: [type::string(read ("HERIT_OBJ"))] ;
		create trees from: cbd_trees ;
		create green from: cbd_green ;
		create wind_avgspeed from: cbd_wind_avgspeed with: [type::string(read ("WSPEED_MSC"))] ;
		create wind_avgdirection from: cbd_wind_direction;
		
		free_space <- copy(shape);
		//Creation of the buildinds
		create building from: cbd_buildings with: [type::string(read ("footprin_1"))] {
			//Creation of the free space by removing the shape of the different buildings existing
			free_space <- free_space - (shape + windparticle_size);
		}
		//Simplification of the free_space to remove sharp edges
		free_space <- free_space simplification(1.0);
		//Creation of the windparticle agents
		create windparticle number: nb_windparticle {
			//windparticle agents are placed randomly among the free space
			location <- any_location_in(free_space);
			target_loc <-  target_point;
		} 		 	
		create wastewater from: cbd_buildings;
		create fox number:100;
		create bird number:100{
			green tmp_green<-one_of(green);
			location<-any_location_in(one_of(tmp_green));
			my_home<-tmp_green;
		}
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
		if (type="Commercial Accommodation"or"Institutional Accommodation"or"Student Accommodation"){
			color<-#black;
			}
		if (type="Community Use"){
			color<-#green;
			}
		if (type="Educational/Research"){
			color<-#blue;
			}
		if (type="Entertainment/Recreation - Indoor"or"Performances, Conferences, Ceremonies"){
			color<-#orange;
			}
		if (type="Hospital/Clinic"){
			color<-#white;
			}
		if (type="House/Townhouse"or"Residential Apartment"){
			color<-#white;
			}
		if (type="Retail - Shop"or"Retail - Showroom"or"Wholesale"){
			color<-#white;
			}
		if (type="Office"or"Workshop/Studio"){
			color<-#white;
			}
		if (type="Parking - Commercial Covered"or"Parking - Private Covered"){
			color<-#white;
			}
		if (type="Transport"){
			color<-#white;
			}
		
			draw shape color:color;
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
species wind_avgspeed {
	string type;
	int mydepth;
	
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
species windparticle skills:[moving] {
	point target_loc;
	float speed <- 0.5 + rnd(1000) / 1000;
	point velocity <- {0,0};
	float heading max: heading + maximal_turn min: heading - maximal_turn;
	float size <- windparticle_size; 
	rgb color <- rgb(rnd(255),rnd(255),rnd(255));
	reflex end when: location distance_to target_loc <= 2 * windparticle_size{
		write name + " is arrived";
		do die;
		}
	reflex follow_goal  {
		velocity <- velocity + ((target_loc - location) / cohesion_factor);
	}
	reflex separation {
		point acc <- {0,0};
		ask (windparticle at_distance size)  {
			acc <- acc - (location - myself.location);
		}  
		velocity <- velocity + acc;
	}
	reflex avoid { 
		point acc <- {0,0};
		list<building> nearby_obstacles <- (building at_distance windparticle_size);
		loop obs over: nearby_obstacles {
			acc <- acc - (obs.location - location); 
		}
		velocity <- velocity + acc; 
	}
	reflex move {
		point old_location <- copy(location);
		do goto target: location + velocity ;
		if not(self overlaps free_space ) {
			location <- ((location closest_points_with free_space)[1]);
		}
		velocity <- location - old_location;
	}
	aspect default {
		draw pyramid(size) color: color;
		draw sphere(size/3) at: {location.x,location.y,size*0.75} color: color;
	}
}

//Experiment GUI
experiment life type: gui {		
	output synchronized:true{
		display city_display type:3d {
			species border aspect:base ;
			species building aspect:base visible:show_building;
			species water aspect:base visible:show_water;
			species heritage_building aspect:base visible:show_heritage;
			species trees aspect:base visible:show_tree;
			species green aspect:base visible:show_green;
			//species wastewater aspect:base;
			species fox aspect:base  visible:show_fox;
			species bird aspect:base  visible:show_fox;
			species wind_avgspeed aspect:base visible:show_wind_avgspeed;
			species wind_avgdirection aspect:base visible:show_wind_avgspeed;
			
			event "b"  {show_building<-!show_building;}
			event "h"  {show_heritage<-!show_heritage;}
			event "t"  {show_tree<-!show_tree;}
			event "w"  {show_water<-!show_water;}
			event "f"  {show_fox<-!show_fox;}
			event "g"  {show_green<-!show_green;}
			event "q"  {show_wind_avgspeed<-!show_wind_avgspeed;}
		}
	}
	
	
	parameter "nb windparticle" var: nb_windparticle min: 1 max: 1000;
	float minimum_cycle_duration <- 0.04; 
	output {
		display map type: 3d {
			species building refresh: false;
			species windparticle;
			graphics "exit" refresh: false {
				draw sphere(2 * windparticle_size) at: target_point color: #green;	
			}
		}
	}
}

