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
	file cbd_dark <- file("../includes/GIS/microclimate/Shadow/cbd_darkness.shp");	
	file cbd_light <- file("../includes/GIS/microclimate/Shadow/cbd_lightness.shp");
	bool show_shadow;	
	action initShadowModel{
		create shadow from: cbd_shadows;
		create darkarea from:cbd_dark;
		create lightarea from:cbd_light;
		show_shadow<-true;
	}
	
	
}


species shadow {
	string type;
	rgb color <- #black;
	aspect base{
		draw shape color:color;
	}
}


species darkarea{
	int darkness;
	aspect base{
		draw shape color:#red;
	}
}

species lightarea{
	int lightness;
	aspect base{
		draw shape color:#green;
	}
}
