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
	geometry shape <- envelope(shape_file_bounds);
	
	float step <- 0.5 #mn;
	float max_speed <- 100.0 #km / #h;

	// Use height to have a influence on the size of shadow;
	int location_x_shift <- -10;// -5 - height * 0.01;
	int location_y_shift <- 10;
	//int scale_shift <- 2;
	
	bool show_building<-true;
	bool show_fix_shadow<-true;
	bool show_moving_shadow<-true;

	
	init{
		create border from: shape_file_bounds ;
		create building from: cbd_buildings with: [type::string(read ("predominan")),mydepth::int(read ("footprin_1"))] ;
		create freezeshadow from: cbd_buildings{
			location <- {location.x+location_x_shift*1.5, location.y+location_y_shift*1.5};
		}
		create moveshadow from: cbd_buildings with: [mydepth::int(read ("footprin_1"))]{
			location <- {location.x+location_x_shift*1.5, location.y+location_y_shift*1.5};
			//speed <- max_speed ;
		}
	}
	
	reflex updateSunlocation{
		//location_x_shift<-
		
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

species freezeshadow {
	string type;
	rgb color <- #black;
	
	aspect base{
		draw shape color:color;
	}
}

species moveshadow {
	string type;
	rgb color;
	int mydepth;
	
	reflex move{
		location<-{location.x+location_x_shift*sin(cycle)*mydepth*0.0006,location.y-location_x_shift*sin(cycle)*mydepth*0.0006}; 
	}
	
	aspect base{
		draw shape color:#black;
	}
}


experiment life type: gui {		
	output synchronized:true{		
		display city_display_shadow type:3d {
			species border aspect:base ;
						
			
			species freezeshadow aspect:base visible:show_fix_shadow;
			species moveshadow aspect:base visible:show_moving_shadow;
			species building aspect:base visible:show_building;
		
			event "b"  {show_building<-!show_building;}
			event "f"  {show_fix_shadow<-!show_fix_shadow;}
			event "m"  {show_moving_shadow<-!show_moving_shadow;}

		}
	}
}