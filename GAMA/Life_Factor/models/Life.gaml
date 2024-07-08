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
	geometry shape <- envelope(shape_file_bounds);
	init{
		create border from: shape_file_bounds ;
	}
	
}

species border {
	aspect base {
		draw shape color:#blue width:2 wireframe:true;
	}
}



experiment life type: gui {		
	output {
		display city_display type:3d {
			species border aspect:base ;
		}
	}
}

