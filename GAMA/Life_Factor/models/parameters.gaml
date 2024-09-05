/**
* Name: Life
* Based on the internal empty template. 
* Author: arno
* Tags: 
*/


model Life

/* Insert your model definition here */

global{
	
  file shape_file_bounds <- file("../includes/GIS/cbd_bounds.shp");	
  file cbd_buildings <- file("../includes/GIS/cbd_buildings.shp");
  file cbd_buildings_heritage <- file("../includes/GIS/cbd_buildings_heritage.shp");
  file cbd_proposals<-file("../includes/GIS/cbd_proposalunion.shp");
  file cbd_trees <- file("../includes/GIS/cbd_trees.shp");	
		
	
  map<string,rgb> model_color<-["human"::rgb(255,218,136),"shadow"::rgb(99,98,98), "water"::rgb(64,88,163), "wind"::rgb(201, 89,63), "biodiversity"::rgb(151,160,95)];	

  map<string,rgb> landuse_color<-["Commercial Accomodation"::rgb(232, 199, 170),"Community Use"::rgb(175, 165, 202), 
	"Educational/Research"::rgb(227, 183, 183), "Entertainment/Recreation - Indoor"::rgb(190, 213, 186), "Equipment Installation"::rgb(205, 222, 188),
	"Hospital/Clinic"::rgb(217, 183, 205), "House/Townhouse"::rgb(238, 238, 190), "Institutional Accommodation"::rgb(227, 181, 168), "Office"::rgb(185, 170, 201),
	"Parking - Commercial Covered"::rgb(137, 136, 136),"Parking - Private Covered"::rgb(53, 53, 53),"Performances, Conferences, Ceremonies"::rgb(177, 209, 193)
	,"Public Display Area"::rgb(170, 177, 210),"Residential Apartment"::rgb(237, 229, 186),"Retail - Shop"::rgb(170, 187, 217),"Retail - Showroom"::rgb(171, 196, 227)
	,"Storage"::rgb(203, 200, 200),"Student Accommodation"::rgb(237, 214, 178),"Transport"::rgb(225, 233, 192),"Wholesale"::rgb(178, 209, 205),"Workshop/Studio"::rgb(176, 209, 228),
	"heritage"::rgb(209,164,113)];
}


species border {
	aspect base {
		draw shape color:#gray width:2 wireframe:true;
	}
}


species building {
	string type;
	rgb color;

	aspect base{
		if(landuse_color[type]=nil){
			color<-rgb(236,233,232);
		}else{
			color<-landuse_color[type];
		}
		draw shape color:color border:#black;
	}
}

species heritage_building {
	string type;
	int mydepth;
		
	aspect base {
		draw shape color:landuse_color["heritage"] border:#black;		
	}
}


species proposal{
	string type;
	string name;
	float height;
	aspect base{
		draw shape color:(type="Green")? #green : ((type="Built")? #brown : #blue)	depth:height;
	}
}






