/**
* Name: Life
* Based on the internal empty template. 
* Author: arno
* Tags: 
*/


model Life_Water

import './parameters.gaml'

/* Insert your model definition here */

global{
	file cbd_water_flow <- file("../includes/GIS/cbd_water_flow.shp");
	file cbd_water_channel <- file("../includes/GIS/microclimate/Water/cbd_water_flowroute.shp");
	file cbd_poi_file <- shape_file("../includes/GIS/microclimate/Water/cbd_water_poi.shp");
	graph water_channel;

	bool show_water_channel<-false;
	bool show_poi<-false;
	bool show_water<-false;
	
	
	action initWaterModel{
		create waste_water_channel from: cbd_water_channel;
		create poi from: cbd_poi_file;
		water_channel <- as_edge_graph(waste_water_channel);
		create wastewater from: cbd_buildings;
	}
	
	//WATER MODEL
	reflex create_water{
		create water number:4{
			poi tmpSource<-one_of(poi where (each.type = "source"));
			location <- tmpSource.location;
			river_id<-tmpSource.river_id;
			target <- one_of(poi where ((each.type = "outlet") and (each.river_id=self.river_id))) ;
		}
	}
}


species water skills: [moving] {
	poi target ;
	int river_id;

	reflex move {
		do goto target: target on: water_channel speed: 30.0;
	}	
	
	aspect base {
		draw circle(8) color: model_color["water"];
	}
}

species poi {
	string type;
	int river_id;
	
	aspect base{
		draw circle(12) color: (type="source") ? #grey : #red border: (type="source") ? #grey : #red wireframe:true;		
	}	
}



species waste_water_channel{
	aspect base {
		draw shape width:1 color:model_color["water"];		
	}
}

species wastewater{
	aspect base {
		draw circle(2) color:#red ;
	}
}



