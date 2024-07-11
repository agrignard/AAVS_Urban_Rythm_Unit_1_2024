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
	file cbd_shadows <- file("../includes/GIS/microclimate/Shadow/cbd_shadow.shp");
	
	geometry shape <- envelope(shape_file_bounds);
	
	
	bool show_building<-true;
	bool show_fix_shadow<-true;
	bool show_plant<-true;
	
	init{
		create border from: shape_file_bounds ;
		create building from: cbd_buildings with: [type::string(read ("predominan")),mydepth::int(read ("footprin_1"))] ;
		create freezeshadow from: cbd_shadows;
	}
	
	reflex updatePlant when: (cycle=0){
		ask freezeshadow{
			if(flip(0.1)){
				create plant number:1{		  	
			  		size<-5+rnd(8);
					initialLifeSpan<-1+rnd(50);
					lifespan<-initialLifeSpan;
					color<-#yellow;
					location<-any_location_in(myself.shape);
			    }
			}
		   
		}
	}
}


species plant{
	
	rgb color;
	int lifespan;
	int size;
	int initialLifeSpan;
	
	reflex liveandletdie{
		lifespan<-lifespan-1;
		if(lifespan=0){
			do die;
		}
	}
	
	aspect base{
		draw circle(size-(cycle/lifespan)) depth: 1.0 color:color border:color-25;
	}
}

species border {
	aspect base {
		draw shape color:#red width:2 wireframe: true;
	}
}

species building {
	string type;
	rgb color <- #darkblue;
	int mydepth;
	aspect base {
		draw shape color:color wireframe:true;
		
	}
}

species freezeshadow {
	string type;
	rgb color <- #black;
	aspect base{
		draw shape color:color;
	}
}


experiment life type: gui autorun:true{		
	output synchronized:true {		
		display city_display_shadow type:2d fullscreen:true{
			
			species border aspect:base;
			species building aspect:base;
			species freezeshadow aspect:base visible:show_fix_shadow;
			species plant aspect:base;
		
			event "b"  {show_building<-!show_building;}
			event "f"  {show_fix_shadow<-!show_fix_shadow;}
			event "p" {show_plant<-!show_plant;}

		}
	}
}