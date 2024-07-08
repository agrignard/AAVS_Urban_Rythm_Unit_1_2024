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
	file cbd_water_flow <- file("../includes/GIS/cbd_water_flow.shp");
	file cbd_buildings_heritage <- file("../includes/GIS/cbd_buildings_heritage.shp");
	file cbd_transport_pedestrian <- file("../includes/GIS/cbd_pedestrian_network_custom.shp");
	file cbd_trees <- file("../includes/GIS/cbd_trees.shp");
	file cbd_green <- file("../includes/GIS/cbd_green.shp");
	geometry shape <- envelope(shape_file_bounds);
	
	bool show_building<-true;
	bool show_heritage<-true;
	bool show_tree<-true;
	bool show_green<-true;
	bool show_water<-true;
	bool show_fox<-true;
	
	init{
		create border from: shape_file_bounds ;
		create building from: cbd_buildings with: [type::string(read ("predominan"))] ;
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
			
			event "b"  {show_building<-!show_building;}
			event "h"  {show_heritage<-!show_heritage;}
			event "t"  {show_tree<-!show_tree;}
			event "w"  {show_water<-!show_water;}
			event "f"  {show_fox<-!show_fox;}
			event "g"  {show_green<-!show_green;}
		}
	}
}

