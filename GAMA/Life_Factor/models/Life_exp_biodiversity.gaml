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
	file cbd_bird_entrance <- file("../includes/GIS/microclimate/Biodiversity/biodiversity_bird_entrancepoint.shp");
	file cbd_bird_path <- file("../includes/GIS/microclimate/Biodiversity/biodiversity_bird_migration.shp");

	graph bird_channel;	
	int bird_population<-1000;
	
	
	geometry shape <- envelope(shape_file_bounds);
	
	float step <- 0.5 #mn;
	float max_speed <- 100.0 #km / #h;

	
	bool show_building<-true;
	bool show_fix_shadow<-true;
	bool show_moving_shadow<-true;

	
	init{
		create border from: shape_file_bounds ;
		create building from: cbd_buildings with: [type::string(read ("predominan")),mydepth::int(read ("footprin_1"))] ;
		
		create bird_gate from:cbd_bird_entrance with: [targets:string(read ("targets"))]{
			self.shape<-circle(100) at_location self.location;
			myTargets<-(targets split_with ',');
		}
		create bird_path from:cbd_bird_path;
		bird_channel <- as_edge_graph(cbd_bird_path);
	}
	
	reflex createBird{
		if(length(bird)<bird_population){
			ask bird_gate{
				create bird number:10{
					location <-myself.location;
					string target_id<-one_of(myself.myTargets);
					exit_gate<-first((bird_gate where  (each.id = target_id)));
				}
		    }
		}
	}
}

species border {
	aspect base {
		draw shape color:#red width:2 wireframe: true;
	}
}

species building {
	string type;
	rgb color <- #darkblue ;
	int mydepth;
		
	aspect base {
		draw shape color:color wireframe:false;
	}
}

species bird skills:[moving]{
	point entry_point;
	bird_gate exit_gate;
	
	reflex move{
		do goto target:exit_gate on:bird_channel;
		if(self.shape intersects exit_gate.shape){
			do die;
		}
	}
	
	aspect base{
		draw triangle(20) rotate: heading+90 color:#pink border:#black;
	}
}

species bird_gate{
	string id;
	string targets;
	list<string> myTargets;
	aspect base{
		draw square(50) color:#green border:#black;
	}
}


species bird_path{
	aspect base{
		draw shape width:2 color:#green border:#black;
	}
}


experiment life type: gui {		
	output synchronized:true{		
		display city_display_shadow type:3d {
			
			species border aspect:base ;
			species bird_gate aspect:base;	
			species bird_path aspect:base;	
			species bird aspect:base;
			
			event "b"  {show_building<-!show_building;}
			event "f"  {show_fix_shadow<-!show_fix_shadow;}
			event "m"  {show_moving_shadow<-!show_moving_shadow;}
		}
	}
}