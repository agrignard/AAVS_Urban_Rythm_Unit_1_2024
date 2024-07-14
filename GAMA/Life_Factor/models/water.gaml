/**
* Name: Life
* Based on the internal empty template. 
* Author: arno
* Tags: 
*/


model Life_Water

/* Insert your model definition here */

global{
	file cbd_water_flow <- file("../includes/GIS/cbd_water_flow.shp");
	file cbd_water_channel <- file("../includes/GIS/microclimate/Water/cbd_water_flowroute.shp");
	file cbd_poi_file <- shape_file("../includes/GIS/microclimate/Water/cbd_water_poi.shp");
	graph water_channel;
	
	action initWaterModel{
		create waste_water_channel from: cbd_water_channel;
		create poi from: cbd_poi_file;
		water_channel <- as_edge_graph(waste_water_channel);
	}
}


species water skills: [moving] {
	poi target ;
	int river_id;

	reflex move {
		do goto target: target on: water_channel speed: 30.0;
	}	
	
	aspect base {
		draw circle(10) color: #blue /*border: #black*/;
	}
}

species poi {
	string type;
	int river_id;
	
	aspect base{
		draw circle(10) color: (type="source") ? #grey : #red border: #black;		
	}	
}



species waste_water_channel{
	aspect base {
		draw shape width:1 color: #darkblue;		
	}
}



