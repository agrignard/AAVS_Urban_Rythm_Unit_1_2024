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
	file cbd_water_flow <- file("../includes/GIS/cbd_water_flow.shp");
	file cbd_water_channel <- file("../includes/GIS/microclimate/Water/cbd_water_flowroute.shp");
	file cbd_poi_file <- shape_file("../includes/GIS/microclimate/Water/cbd_water_poi.shp");
	graph the_channel;
	file cbd_buildings_heritage <- file("../includes/GIS/cbd_buildings_heritage.shp");
	file cbd_transport_pedestrian <- file("../includes/GIS/cbd_pedestrian_network_custom.shp");
	file cbd_trees <- file("../includes/GIS/cbd_trees.shp");
	file cbd_green <- file("../includes/GIS/cbd_green.shp");
	
	file cbd_proposals<-file("../includes/GIS/cbd_proposals.shp");
	geometry shape <- envelope(shape_file_bounds);
	
	bool show_scenario_1<-false;
	bool show_scenario_2<-false;
	bool show_scenario_3<-false;
	
	bool show_landuse<-false;
	bool show_heritage<-false;
	bool show_shadow<-false;
	bool show_wind_model<-false;
	bool show_water_model<-false;
	bool show_water_channel<-false;
	bool show_poi<-false;
	bool show_water<-false;
	bool show_shadow_model<-false;
	bool show_biodiversity_model<-false;
	bool show_fox<-false;
	bool show_bird<-false;
	bool show_bird_gate<-false;
	bool show_green<-true;
	bool show_tree<-false;
	
	bool show_legend<-true;
	rgb text_color<-rgb(125,125,125);
	string myFont;
	
	init{
		create border from: shape_file_bounds ;
		create building from: cbd_buildings with: [type::string(read ("predominan"))] ;
		create proposal from: cbd_proposals with: [type::string(read ("type")),name::string(read ("name")),height::float(read ("height"))] ;
		
		
		//SHADOW MODEL
		create freezeshadow from: cbd_shadows;
		
		//WATER MODEL
		create waste_water_channel from: cbd_water_channel;
		create poi from: cbd_poi_file;
		the_channel <- as_edge_graph(waste_water_channel);
		
		//BIRD MODEL
		file cbd_bird_entrance <- file("../includes/GIS/microclimate/Biodiversity/biodiversity_bird_entrancepoint.shp");
	    file cbd_bird_path <- file("../includes/GIS/microclimate/Biodiversity/biodiversity_bird_migration.shp");
	    graph bird_channel;	
	    int bird_population<-1000;
	
		
		
		create heritage_building from: cbd_buildings_heritage with: [type::string(read ("HERIT_OBJ"))] ;
		create trees from: cbd_trees ;
		create green from:cbd_green;
		create wastewater from: cbd_buildings;
		//BIODIVERSITY
		//BIRD
		create bird_gate from:cbd_bird_entrance with: [targets:string(read ("targets"))]{
			self.shape<-circle(100) at_location self.location;
			myTargets<-(targets split_with ',');
		}
		create bird_path from:cbd_bird_path;
		bird_channel <- as_edge_graph(cbd_bird_path);
		
	}
	
	//WATER MODEL
	reflex create_water{
		create water {
			poi tmpSource<-one_of(poi where (each.type = "source"));
			location <- tmpSource.location;
			river_id<-tmpSource.river_id;
			target <- one_of(poi where ((each.type = "outlet") and (each.river_id=self.river_id))) ;
		}
	}
	
	//BIRD MODEL
	reflex createBird when:(cycle mod 20 =0){
			ask bird_gate{
				create bird number:1{
					speed<-1.0+rnd(5.0);
					location <-myself.location;
					shape<-triangle(20);
					string target_id<-one_of(myself.myTargets);
					exit_gate<-first((bird_gate where  (each.id = target_id)));
					my_target<-exit_gate.location;
				}
		    }
	}
	
	//CREATE SCENARIO
	action createScenario(string _name){
		ask proposal where (each.name=_name){
			create green with:[type::_name,shape::self.shape];
		}
	}
	
	action deleteScenario(string _name){
		ask green where (each.type=_name){
			do die;
		}
	}
	
	///MODEL TRIGGER
	
	action triggerShadowModel (bool value){
		show_shadow<-value;
	}
	
	action triggerWaterModel (bool value){
		show_water<-value;
	    show_water_channel<-value;
	    show_poi<-value;
	}
	
	action triggerBiodiversityModel (bool value){
		show_fox<-value;
	    show_bird<-value;
	    show_bird_gate<-value;
	    show_green<-value;
	    show_tree<-value;
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
		if (type="Commercial Accommodation"or"Institutional Accommodation"or"Student Accommodation"){
			color<-rgb(67,64,208);
			}
		if (type="Community Use"){
			color<-rgb(232,206,69);
			}
		if (type="Educational/Research"){
			color<-rgb(116,125,81);
			}
		if (type="Entertainment/Recreation - Indoor"or"Performances, Conferences, Ceremonies"){
			color<-rgb(240,239,175);
			}
		if (type="Hospital/Clinic"){
			color<-rgb(227,165,58);
			}
		if (type="House/Townhouse"or"Residential Apartment"){
			color<-rgb(82,89,55);
			}
		if (type="Retail - Shop"or"Retail - Showroom"or"Wholesale"){
			color<-rgb(188,132,208);
			}
		if (type="Office"or"Workshop/Studio"){
			color<-rgb(82,89,55);
			}
		if (type="Parking - Commercial Covered"or"Parking - Private Covered"){
			color<-rgb(61,62,64);
			}
		if (type="Transport"){
			color<-rgb(51,58,64);
			}
			draw shape color:color border:#black;
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

species freezeshadow {
	string type;
	rgb color <- #black;
	aspect base{
		draw shape color:color;
	}
}

species heritage_building {
	string type;
	int mydepth;
		
	aspect base {
		if (type="N"){
			color<-rgb(131,137,140);
		}
		draw shape color:color border:rgb(82,89,55);		
	}
}


///////WATER MODEL ////////
species water skills: [moving] {
	poi target ;
	int river_id;

	reflex move {
		do goto target: target on: the_channel speed: 30.0;
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


//BIODIVERSITY
species bird skills:[moving]{
	point entry_point;
	green my_green_space;
	bird_gate exit_gate;
	point my_target;
	rgb color<-#pink;
	bool hungry<-false;
	bool full<-false;
	float speed;
	
	
	reflex checkGreen when:(hungry=false and full=false){
		list<green> potentialGreen <- green at_distance 200;
		if (length(potentialGreen)>0){
			my_green_space<-first(potentialGreen);
			my_target <-my_green_space.location;
			color<-#purple;	
			hungry<-true;
		}
	}
	
	reflex move{
		if(my_target!=nil){
			do goto target:my_target speed:speed;// on:bird_channel;
		}else{
			do die;
		}
		
		if(self.shape intersects exit_gate.shape){
			do die;
		}
		if(hungry=true and full=false){
			if(!dead(my_green_space)){
			  if(self.shape intersects my_green_space.shape){
				my_target<-exit_gate.location;
				full<-true;
				hungry<-false;
			  }	
			}else{
				do die;
			}
		}
	}
	
	aspect base{
		draw triangle(20) rotate: heading+90 color:hungry ? #purple : (full ? #green : #red) border:#black;
	}
}

species bird_gate{
	string id;
	string targets;
	list<string> myTargets;
	aspect base{
		draw square(30) color:#gray border:#black;
	}
}


species bird_path{
	aspect base{
		draw shape width:2 color:#green border:#black;
	}
}

species trees {
	aspect base {
		draw circle(3) color:#green;
	}
}

species green{
	string type;
	aspect base {
		draw shape color:#green border:#black;
	}
}
species wastewater{
	aspect base {
		draw circle(2) color:#red ;
	}
}


species fox skills:[moving]{
	aspect base{
		draw triangle(25) rotate:heading+90 color:#brown;
	}
	reflex move{
		do wander speed:1.0;
	}
}


experiment life type: gui autorun:true{
	init{
	  gama.pref_display_numkeyscam<-false;		
	}	
	output synchronized:true{
		display city_display type:3d fullscreen:true{
			species border aspect:base ;
			species building aspect:base visible:show_landuse;
			species freezeshadow aspect:base visible:show_shadow;
			//species proposal aspect:base;
			species waste_water_channel aspect:base visible:show_water_channel;
			species poi aspect:base visible:show_poi;
			species water aspect:base visible:show_water;
			species bird_gate aspect:base position:{0,0,0.01} visible:show_bird_gate;	
			species bird aspect:base  position:{0,0,0.01} visible:show_bird;
			species heritage_building aspect:base visible:show_heritage;
			species trees aspect:base visible:show_tree;
			species green aspect:base visible:show_green;
			species fox aspect:base  visible:show_fox;
			species bird aspect:base  visible:show_bird;
			
			event "1"  {show_shadow_model<-!show_shadow_model;
				if(show_shadow_model){
					ask simulation{do triggerShadowModel(true);}
					
				}else{
					ask simulation{do triggerShadowModel(false);}
				}
			}
			event "2"  {show_water_model<-!show_water_model;
				if(show_water_model){
				  ask simulation{do triggerWaterModel(true);}
				}else{
				  ask simulation{do triggerWaterModel(false);}
				}
				
			}
			event "3"  {show_wind_model<-!show_wind_model;}
			event "4"  {show_biodiversity_model<-!show_biodiversity_model;
				if (show_biodiversity_model){
					ask simulation{do triggerBiodiversityModel(true);}
				}else{
					ask simulation{do triggerBiodiversityModel(false);}
				}
			}
			
			event "5"{show_scenario_1<-!show_scenario_1;
				if (show_scenario_1){
					ask simulation{do createScenario("Abeckett");}
				}else{
					ask simulation{do deleteScenario("Abeckett");}
				}
			}
			event "6"{show_scenario_2<-!show_scenario_2;
				if (show_scenario_2){
					ask simulation{do createScenario("China Town");}
				}else{
					ask simulation{do deleteScenario("China Town");}
				}
			}
			event "7"{show_scenario_3<-!show_scenario_3;
				if (show_scenario_3){
					ask simulation{do createScenario("Parliament");}
				}else{
					ask simulation{do deleteScenario("Parliament");}
				}
			}
		
			event "l"  {show_landuse<-!show_landuse;}
			event "h"  {show_heritage<-!show_heritage;}
			event "t"  {show_tree<-!show_tree;}
			event "w"  {show_water<-!show_water;}
			event "c"  {show_water_channel<-!show_water_channel;}
			event "p"  {show_poi<-!show_poi;}
			event "f"  {show_fox<-!show_fox;}
			event "b"  {show_bird<-!show_bird;}
			event "g"  {show_green<-!show_green;}
			
			overlay position: { 50#px,50#px} size: { 1 #px, 1 #px } background: # black border: #black rounded: false
			{
	
				if(show_legend){
				draw image_file('../images/life.png') at: { 200#px,50#px } size:{120#px,84#px};
				
				//draw "Date: " + current_date at: {0,200#px} color: text_color font: font(myFont, 20, #bold);
				
                
                //point UX_Position<-{world.shape.width*1.25,0#px};
                point UX_Position<-{100#px,200#px};
                float x<-UX_Position.x;
                float y<-UX_Position.y;
        
                float gapBetweenWord<-25#px;
                float tabGap<-25#px;
                float uxTextSize<-20.0;
                
             
                draw "(1) SHADOW MODEL(" + show_shadow_model + ")" at: { x,y} color: text_color font: font(myFont, uxTextSize, #bold);
                if(show_shadow_model){
                	 y<-y+gapBetweenWord;
                	 draw "S(H)ADOW (" + show_shadow + ")" at: { x+tabGap,y} color: text_color font: font(myFont, uxTextSize, #bold);
                }
                y<-y+gapBetweenWord;
                y<-y+gapBetweenWord;
                draw "(2) WATER MODEL(" + show_water_model + ")" at: { x,y} color: text_color font: font(myFont, uxTextSize, #bold);
                if(show_water_model){
                	 y<-y+gapBetweenWord;
                	 draw "WATER (C)HANNEL (" + show_water_channel + ")" at: { x+tabGap,y} color: text_color font: font(myFont, uxTextSize, #bold);
                	 y<-y+gapBetweenWord;
                	 draw "(P)RODUCER (" + show_poi + ")" at: { x+tabGap,y} color: text_color font: font(myFont, uxTextSize, #bold);
                	 y<-y+gapBetweenWord;
                	 draw "(W)ATER (" + show_water + ")" at: { x+tabGap,y} color: text_color font: font(myFont, uxTextSize, #bold);
                }
                y<-y+gapBetweenWord;
                y<-y+gapBetweenWord;
                draw "(3) WIND MODEL (" + show_wind_model + ")" at: { x,y} color: text_color font: font(myFont, uxTextSize, #bold);
                y<-y+gapBetweenWord;
                y<-y+gapBetweenWord;
                draw "(4) BIODIVERSITY MODEL(" + show_biodiversity_model + ")" at: { x,y} color: text_color font: font(myFont, uxTextSize, #bold);
               
                if(show_biodiversity_model){
                	y<-y+gapBetweenWord;
                	draw "(G)REEN (" + show_green + ")" at: { x+tabGap,y} color: text_color font: font(myFont, uxTextSize, #bold);
                	y<-y+gapBetweenWord;  
	                draw "(F)OX (" + show_fox + ")" at: { x+tabGap,y} color: text_color font: font(myFont, uxTextSize, #bold);
	                y<-y+gapBetweenWord;
	                draw "(B)IRD (" + show_bird + ")" at: { x+tabGap,y} color: text_color font: font(myFont, uxTextSize, #bold);
	                
                }
                y<-y+gapBetweenWord;
                y<-y+gapBetweenWord;
                draw "SCENARIO 1(5) (" + show_scenario_1 + ")" at: { x,y} color: text_color font: font(myFont, uxTextSize, #bold);
                y<-y+gapBetweenWord;
                draw "SCENARIO 2(6) (" + show_scenario_2 + ")" at: { x,y} color: text_color font: font(myFont, uxTextSize, #bold);
                y<-y+gapBetweenWord;
                draw "SCENARIO 3(7) (" + show_scenario_3 + ")" at: { x,y} color: text_color font: font(myFont, uxTextSize, #bold);
                y<-y+gapBetweenWord;
                y<-y+gapBetweenWord;
                draw "(L)ANDUSE (" + show_landuse + ")" at: { x,y} color: text_color font: font(myFont, uxTextSize, #bold);
                y<-y+gapBetweenWord;
                draw "(H)ERITAGE (" + show_heritage + ")" at: { x,y} color: text_color font: font(myFont, uxTextSize, #bold);
                y<-y+gapBetweenWord;
 
               
                 
			}				
		  }
		}
	}
}