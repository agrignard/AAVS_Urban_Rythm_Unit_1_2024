/**
* Name: Life
* Based on the internal empty template. 
* Author: arno
* Tags: 
*/


model Life

import "./parameters.gaml"
import "./wind.gaml"

/* Insert your model definition here */

global{
	 //Microclimate_wind
	geometry shape <- envelope(shape_file_bounds);
	bool show_landuse<-true;
	bool show_avgwindspeed<-false;
	bool show_avgwinddirection<-true;
	bool show_windborder<-false;
	
	init{		
		create border from: shape_file_bounds ;		
		create building from: cbd_buildings with: [type::string(read ("predominan"))] ;
		do initWindModel(cbd_buildings);
	}	
}

experiment life type: gui {		
	output synchronized:true{
		display city_display type:3d {
			species border aspect:base ;
			species building aspect:base visible:show_landuse;
			species wind_avgspeed aspect:base  visible:show_avgwindspeed;
			species windborder aspect:base  visible:show_windborder;
			species global_wind_point aspect:base position:{0,0,0.01};
			species global_wind_flow aspect:base position:{0,0,0} trace:5 fading:true;
			species wind_avgdirection aspect:base  visible:show_avgwinddirection position:{0,0,0.0};
			species windy_building aspect:base;
			species windparticle aspect:abstract position:{0,0,0.0} trace:5 fading:true;
		}
	}
}