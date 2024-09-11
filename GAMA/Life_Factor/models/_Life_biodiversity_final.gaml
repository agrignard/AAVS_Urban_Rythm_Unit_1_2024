/**
* Name: Life
* Based on the internal empty template. 
* Author: arno
* Tags: 
*/


model Life

import "./parameters.gaml"

/* Insert your model definition here */

global{
	file shape_file_bounds <- file("../includes/GIS/cbd_border.shp");
	file cbd_buildings <- file("../includes/GIS/cbd_buildings.shp");	
	file cbd_bird_entrance <- file("../includes/GIS/microclimate/Biodiversity/biodiversity_bird_entrancepoint.shp");
	file cbd_bird_path <- file("../includes/GIS/microclimate/Biodiversity/biodiversity_bird_migration.shp");
	file cbd_green <- file("../includes/GIS/cbd_green.shp");
	file cbd_proposal_1 <- file("../includes/GIS/cbd_proposal_1.shp");
	file cbd_proposal_2 <- file("../includes/GIS/cbd_proposal_2.shp");
	file cbd_proposal_3 <- file("../includes/GIS/cbd_proposal_3.shp");
	file cbd_proposals<-file("../includes/GIS/cbd_proposalunion.shp");

	graph bird_channel;	
	int bird_population<-1000;
	
	
	geometry shape <- envelope(shape_file_bounds);
	
	float step <- 0.5 #mn;
	float max_speed <- 100.0 #km / #h;

	
	bool show_building<-true;
	bool show_gate<-true;
	bool show_bird<-true;
	bool show_park<-true;
	
	bool show_proposal;
	bool show_proposal_1;
	bool show_proposal_2;
	bool show_proposal_3;

	
	init{
		create border from: shape_file_bounds ;
		if(show_proposal){
		  create proposal from: cbd_proposals with: [type::string(read ("type")),name::string(read ("name")),height::float(read ("height"))] ;
		}		
		
		create bird_gate from:cbd_bird_entrance with: [targets:string(read ("targets"))]{
			self.shape<-circle(100) at_location self.location;
			myTargets<-(targets split_with ',');
		}
		create bird_path from:cbd_bird_path;
		bird_channel <- as_edge_graph(cbd_bird_path);
		create green from:cbd_green{
			type<-"existing";
	    }
		if(show_proposal_1)
		{
		  create green from:cbd_proposal_1;	
		}	
		if(show_proposal_2)
		{
		  create green from:cbd_proposal_2;	
		}
		if(show_proposal_3)
		{
		  create green from:cbd_proposal_3;	
		}
		
}
	
	
	reflex createBird{
			ask bird_gate{
				create bird number:1{
					speed<-0.1+rnd(1.0);
					location <-myself.location;
					shape<-triangle(20);
					string target_id<-one_of(myself.myTargets);
					exit_gate<-first((bird_gate where  (each.id = target_id)));
					my_target<-exit_gate.location;
				}
		    }
	}
}




species bird skills:[moving]{
	point entry_point;
	green my_green_space;
	bird_gate exit_gate;
	point my_target;
	rgb color<-#pink;
	bool hungry<-false;
	bool full<-false;
	float speed;
	
	reflex checkGreen when:(hungry=false and full=false){
		list<green> potentialGreen <- green at_distance 150;
		if (length(potentialGreen)>0){
			my_green_space<-first(potentialGreen);
			my_target <-my_green_space.location;
			color<-#purple;	
			hungry<-true;
		}
	}
	
	reflex move{
		do goto target:my_target speed:speed;// on:bird_channel;
		
		if(self.shape intersects exit_gate.shape){
			do die;
		}
		if(hungry=true and full=false){
			if(self.shape intersects my_green_space.shape){
				my_target<-exit_gate.location;
				full<-true;
				hungry<-false;
			}
		}
	}
	
	aspect base{
		draw triangle(20) rotate: heading+90 color:hungry ? rgb(91,122,55) : (full ? model_color["bio_green"] : rgb(177,209,193)) border:#black;
	}
}

species bird_gate{
	string id;
	string targets;
	list<string> myTargets;
	aspect base{
		draw square(30) color:#gray border:#black;
	}
}


species bird_path{
	aspect base{
		draw shape width:2 color:#green border:#black;
	}
}



species green{
	string type;
	aspect base {
		draw shape color:rgb(26,61,43);
	}
}

experiment life_2024 type: gui {	
	float minimum_cycle_duration<-0.05;	
	output synchronized:true
	{		
		display city_display_shadow type:3d fullscreen:true autosave:false{		
			
			species green aspect:base;
			species border aspect:base ;
			species proposal aspect:base;
			species bird_gate aspect:base position:{0,0,0.01};		
			species bird aspect:base  position:{0,0,0.05};	
			species building aspect:base visible:show_building transparency:0.4;
			event "p"  {show_park<-!show_park;}
			event "g"  {show_gate<-!show_gate;}
			event "b"  {show_bird<-!show_bird;}
		}
	}
}

experiment life_full type: gui {	
	float minimum_cycle_duration<-0.05;	
	init{
		//we create a second simulation (the first simulation is always created by default) with the following parameters
		create simulation with: [show_proposal_1::true,show_proposal:: true];
		create simulation with: [show_proposal_2::true,show_proposal:: true];
		create simulation with: [show_proposal_3:: true,show_proposal:: true];
	}
	output synchronized:true
	{	
			
		display city_display_shadow type:3d {		
			species building aspect:base visible:show_building ;
			species green aspect:base;
			species border aspect:base ;
			species proposal aspect:base;
			species bird_gate aspect:base position:{0,0,0.01};		
			species bird aspect:base  position:{0,0,0.05};	
			event "p"  {show_park<-!show_park;}
			event "g"  {show_gate<-!show_gate;}
			event "b"  {show_bird<-!show_bird;}
		}
	}
}