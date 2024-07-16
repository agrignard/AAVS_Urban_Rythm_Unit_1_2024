/**
* Name: Life
* Based on the internal empty template. 
* Author: arno
* Tags: 
*/


model Life_Shadow

/* Insert your model definition here */

global{

	file cbd_shadows <- file("../includes/GIS/microclimate/Shadow/cbd_shadow.shp");	
	action initShadowModel{
		create shadow from: cbd_shadows;
	}
	
	bool show_shadow<-false;
}


species shadow {
	string type;
	rgb color <- #black;
	aspect base{
		draw shape color:color;
	}
}



