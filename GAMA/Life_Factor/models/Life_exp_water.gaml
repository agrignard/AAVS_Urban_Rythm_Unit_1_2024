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
	file cbd_water_channel <- file("../includes/GIS/microclimate/Water/cbd_water_flowroute.shp");
	file cbd_poi_file <- shape_file("../includes/GIS/microclimate/Water/cbd_water_poi.shp");
	file cbd_buildings_heritage <- file("../includes/GIS/cbd_buildings_heritage.shp");
	file cbd_transport_pedestrian <- file("../includes/GIS/cbd_pedestrian_network_custom.shp");
	file cbd_trees <- file("../includes/GIS/cbd_trees.shp");
	file cbd_green <- file("../includes/GIS/cbd_green.shp");
	geometry shape <- envelope(shape_file_bounds);

	graph the_channel;
	
	bool show_landuse<-false;
	bool show_heritage<-false;
	bool show_tree<-false;
	bool show_green<-false;
	bool show_water<-true;
	bool show_fox<-false;
	bool show_bird<-false;
	bool show_wastewater<-true;
	
	init{
		create border from: shape_file_bounds ;
		create building from: cbd_buildings with: [type::string(read ("predominan"))] ;
		create heritage_building from: cbd_buildings_heritage with: [type::string(read ("HERIT_OBJ"))] ;
		create trees from: cbd_trees ;
		create green from:cbd_green;
		create waste_water_channel from: cbd_water_channel;
		create poi from: cbd_poi_file;
		create fox number:100;
		create bird number:100{
			green tmp_green<-one_of(green);
			location<-any_location_in(one_of(tmp_green));
			my_home<-tmp_green;
		}
		the_channel <- as_edge_graph(waste_water_channel);
	}
	
	reflex create_water{
		create water {
			poi tmpSource<-one_of(poi where (each.type = "source"));
			location <- tmpSource.location;
			river_id<-tmpSource.river_id;
			target <- one_of(poi where ((each.type = "outlet") and (each.river_id=self.river_id))) ;
		}
	}
	
}

species border {
	aspect base {
		draw shape color:#grey width:2 wireframe:true;
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

species water skills: [moving] {
	poi target ;
	int river_id;

	reflex move {
		do goto target: target on: the_channel speed: 30.0;
	}	
	
	aspect base {
		draw circle(10) color: #blue /*border: #black*/;
	}
}

species poi {
	string type;
	int river_id;
	
	aspect base{
		draw circle(10) color: (type="source") ? #grey : #red /*border: #black*/;		
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
species waste_water_channel{
	aspect base {
		draw shape width:1 color: #grey;		
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
			species waste_water_channel aspect:base visible:show_wastewater;
			species poi aspect:base;
		
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