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
	bool show_fix_shadow<-false;
	bool show_moving_shadow<-true;

	float rate_of_buildings_to_remove <- 0.5;
	
	init{
		create border from: shape_file_bounds ;
		create building from: cbd_buildings with: [type::string(read ("predominan")),mydepth::int(read ("footprin_1"))]  {
			if flip(rate_of_buildings_to_remove) {do die;}
			convex <- convex_hull(shape);
			create moveshadow  with: [shape::copy(shape), mydepth::mydepth]{
				linked_building <- myself;
				point trans <-{location_x_shift*1.5, location_y_shift*1.5}; 
				do compute_shadow_geom(trans);
				
				//speed <- max_speed ;
				create freezeshadow  with: [shape::copy(shadow_geom)];
			}
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
	rgb color <- #darkblue;
	geometry convex;
	int mydepth;
	aspect base {
		draw shape color:color wireframe:false;
		
	}
	
	list<point>  compute_extremity (point translation) {
		point per <-  {translation.y, -1 * translation.x} ;
		float normPer <-  norm(per);
		if (normPer > 0) {
			float min_v <-  #max_float;
			float max_v<- - #max_float;
			point pt_min;
			point pt_max;
	
			loop p over: convex.points {
				float d <- location distance_to p;
				float a <- angle_between(location, p,per);
				float d_proj <- d * cos(a);
				if (d_proj < min_v) {
					min_v <- d_proj;
					pt_min <- p;
				}
				if (d_proj > max_v) {
					max_v <- d_proj;
					pt_max <- p;
				}
			}
			return [pt_min, pt_max];
		
		} else {
			return [];
		}
	}
}

species freezeshadow {
	string type;
	rgb color <- #black;
	
	aspect base{
		draw shape color:color;
	}
}

species moveshadow parent: building{
	building linked_building;
	geometry shadow_geom;
	
	
	point current_translation <- {0,0};
		
	action compute_shadow_geom(point translation) {
		current_translation <- current_translation + translation;
		list<point> ref_points <- linked_building.compute_extremity(current_translation);
		if empty(ref_points) {
			location <- location + translation;
			shadow_geom <- shape;
		} else {
			geometry poly <- polygon([first(ref_points),last(ref_points),last(ref_points)+current_translation,first(ref_points)+current_translation ]);
			location <- location + translation;
			shadow_geom <- shape union poly ;
		}
		
		 	
	}
	reflex move{
		point trans <-{location_x_shift*sin(cycle)*mydepth*0.0006,-location_x_shift*sin(cycle)*mydepth*0.0006}; 
		do compute_shadow_geom(trans);
		
	}
	
	aspect base{
		draw shadow_geom color:#black;
		
		
		
	}
}


experiment life type: gui {		
	output synchronized:true{		
		display city_display_shadow type:2d {
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