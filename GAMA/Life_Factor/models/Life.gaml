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
	
	bool show_landuse<-true;
	bool show_heritage<-true;
	bool show_tree<-true;
	bool show_green<-true;
	bool show_water<-true;
	bool show_fox<-true;
	bool show_bird<-true;
	
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
		if (type="Commercial Accommodation"or"Institutional Accommodation"or"Student Accommodation"){
			color<-rgb(67,64,208);
			}
		if (type="Community Use"){
			color<-rgb(232,206,69);
			}
		if (type="Educational/Research"){
			color<-rgb(116,125,81);
			}
		if (type="Entertainment/Recreation - Indoor"or"Performances, Conferences, Ceremonies"){
			color<-rgb(240,239,175);
			}
		if (type="Hospital/Clinic"){
			color<-rgb(227,165,58);
			}
		if (type="House/Townhouse"or"Residential Apartment"){
			color<-rgb(82,89,55);
			}
		if (type="Retail - Shop"or"Retail - Showroom"or"Wholesale"){
			color<-rgb(188,132,208);
			}
		if (type="Office"or"Workshop/Studio"){
			color<-rgb(82,89,55);
			}
		if (type="Parking - Commercial Covered"or"Parking - Private Covered"){
			color<-rgb(61,62,64);
			}
		if (type="Transport"){
			color<-rgb(51,58,64);
			}
			draw shape color:color border:#black;
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
			color<-rgb(131,137,140);
		}
		draw shape color:color border:rgb(82,89,55);		
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
			species building aspect:base visible:show_landuse;
			species water aspect:base visible:show_water;
			species heritage_building aspect:base visible:show_heritage;
			species trees aspect:base visible:show_tree;
			species green aspect:base visible:show_green;
			species fox aspect:base  visible:show_fox;
			species bird aspect:base  visible:show_bird;
		
			event "l"  {show_landuse<-!show_landuse;}
			event "h"  {show_heritage<-!show_heritage;}
			event "t"  {show_tree<-!show_tree;}
			event "w"  {show_water<-!show_water;}
			event "f"  {show_fox<-!show_fox;}
			event "b"  {show_bird<-!show_bird;}
			event "g"  {show_green<-!show_green;}
		}
	}
}