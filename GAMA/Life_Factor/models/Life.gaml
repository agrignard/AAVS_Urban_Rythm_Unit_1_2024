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
	init{
		create border from: shape_file_bounds ;
		create building from: cbd_buildings with: [type::string(read ("predominan"))] ;
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
experiment life type: gui {		
	output {
		display city_display type:3d {
			species border aspect:base ;
			species building aspect:base ;
		}
	}
}

