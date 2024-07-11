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
	
	bool show_building<-true;
	bool show_water_channel<-true;
	bool show_poi<-true;
	bool show_water<-true;

	init{
		create border from: shape_file_bounds ;
		create building from: cbd_buildings with: [type::string(read ("predominan"))] ;
		create waste_water_channel from: cbd_water_channel;
		create poi from: cbd_poi_file;
		the_channel <- as_edge_graph(waste_water_channel);
	}
	
	reflex create_water{
		create water number:10{
			speed<-1.0+rnd(25.0);
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
	rgb color <- #purple ;
	int mydepth;
		
	aspect base {
		if (type="Unoccupied - Unused"){
			color<-#darkgrey;
		}
		draw shape color:color wireframe:true;
	}
}

species water skills: [moving] {
	poi target ;
	int river_id;

	reflex move {
		do goto target: target on: the_channel speed:speed;
	}	
	
	aspect base {
		draw circle(4) color: #purple /*border: #black*/;
	}
}

species poi {
	string type;
	int river_id;
	
	aspect base{
		draw circle(12) color: (type="source") ? #purple : #red border: #black;		
	}	
}



species waste_water_channel{
	aspect base {
		draw shape width:1 color: #darkblue;		
	}
}






experiment life type: gui autorun:false{		
	output synchronized:true{
		display city_display type:3d fullscreen:true{
			species border aspect:base ;
			species building aspect:base visible:show_building;
			species waste_water_channel aspect:base visible:show_water_channel;
			species poi aspect:base visible:show_poi;
			species water aspect:base visible:show_water;
			event "b"  {show_building<-!show_building;}
			event "c"  {show_water_channel<-!show_water_channel;}
			event "p"  {show_poi<-!show_poi;}
			event "w"  {show_water<-!show_water;}
		}
	}
}