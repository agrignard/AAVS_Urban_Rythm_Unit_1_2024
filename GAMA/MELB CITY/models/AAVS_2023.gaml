/**
* Name: CBD Toolkit 1.0
* Based on the internal empty template. 
* Author: Arnaud Grignard - AAVS UNit 2023
* Tags: digital twins
*/

model CBDToolKit1

global {
	//GIS FILE
	file shape_file_buildings <- file("../includes/GIS/cbd_buildings.shp");
	file shape_file_cbd_traffic <- file("../includes/GIS/cbd_networks.shp");
	file shape_file_cbd_tram <- file("../includes/GIS/cbd_tram_custom.shp");
	file shape_file_cbd_car <- file("../includes/GIS/cbd_car_custom.shp");
	file shape_file_bounds <- file("../includes/GIS/cbd_bounds.shp");
	file shape_file_hack <- file("../includes/GIS/hack.shp");

	

	file point_file_outside_cbd <- file("../includes/GIS/cbd_coming_from_outside.shp");
	file text_file_population <- file("../includes/data/Demographic_CBD.csv");
	file text_file_car <- file("../includes/data/car_cbd.csv");
	

	
	geometry shape <- envelope(shape_file_bounds);
	
	
	//TEMPORAL 
	float step <- 3600 #sec;
	field cell <- field(300,300);
	date starting_date <- date([2023,7,14,6,0,0]);

	int nb_tram <- 50;
	int nb_car <- 100;
	int nb_bike <- 100;
	float min_tram_speed <- 10.0 #km / #h;
	float max_tram_speed <- 26.0 #km / #h;
	float min_car_speed <- 5 #km / #h;
	float max_car_speed <- 40 #km / #h;
	int min_work_start <- 6;
	int max_work_start <- 8;
	int min_work_end <- 16; 
	int max_work_end <- 20;
	

	graph car_network_graph;
	graph tram_network_graph;
	graph bike_network_graph;
	graph pedestrian_network_graph;
	
	map<int,rgb> age_color<-[1::rgb(33, 158, 188), 2::rgb(33, 158, 188),3::rgb(33, 158, 188), 4::rgb(33, 158, 188),5::rgb(33, 158, 188),5::rgb(33, 158, 188),6::rgb(33, 158, 188)];
	map<int,float> grouptospeed<-[1::3.3 #km / #h, 2::4.5 #km / #h,3::4.5 #km / #h, 4::3.3 #km / #h,5::3.3 #km / #h];
   
	
	map<string,rgb> landuse_color<-["residential"::rgb(231, 111, 81),"mixed"::rgb(244, 162, 97),"university"::rgb(38, 70, 83), "office"::rgb(42, 157, 143), "retail"::rgb(233, 196, 106)
		, "entertainment"::rgb(33, 158, 188),"carpark"::rgb(92, 103, 125),"park"::rgb(153, 217, 140)];
	map<string,rgb> building_usage_color<-["residential"::rgb(201, 81, 61),"mixed"::rgb(244, 162, 97),"university"::rgb(38, 70, 83),  "work"::rgb(42, 157, 143), "retail"::rgb(30,233,182),"entertainment"::rgb(33, 158, 188)];	
	map<string,rgb> path_type_color<-["car"::rgb(car_color),"bike"::rgb(bike_color),"tram"::rgb(tram_color),"people"::rgb(people_color),"bus"::rgb(bus_color)];

   
    //ABM
    bool simpleSimulation<-true;   
	
	//UX/UI
	bool show_building<-false;
	bool show_landuse<-true;
	bool show_tram<-true;
	bool show_car<-true;
	bool show_bike<-true;
	bool show_people<-true;
	bool show_network<-true;
	bool show_mode_legend<-false;
	bool show_legend<-true;
	
	//v2
	bool show_heatmap<-false;
		
	//VISUAL
	rgb background_color<-rgb(0,0,0);
	rgb text_color<-rgb(255,255,255);
	rgb building_color<-rgb(102,102,102);
	rgb people_color<-rgb(255,222,94);
	rgb car_color<-rgb(244,40,41);
	rgb bus_color<-rgb(0,64,255);
	rgb bike_color<-rgb(217,111,248);
	rgb tram_color<-rgb(30,233,182);

	float network_line_width<-2#px;
	
	string myFont;
	
	//POLUTION COLOR
	list<rgb> pal <- palette([ #black, #green, #yellow, #orange, #orange, #red, #red, #red]);
	map<rgb,string> pollutions <- [#green::"Good",#yellow::"Average",#orange::"Bad",#red::"Hazardous"];
	map<rgb,string> legends <- [rgb(231, 111, 81)::"residential",rgb(42, 157, 143)::"office",rgb(244, 162, 97)::"mixed",rgb(233, 196, 106)::"retail",rgb(38, 70, 83)::"university", rgb(33, 158, 188)::"entertainment"];
	font text <- font("Arial", 14, #bold);
	font title <- font("Arial", 18, #bold);
	

	//PLOT
	map<rgb,string> legends_pie <- [rgb(71,42,22)::"car",rgb(161,106,69)::"bike", rgb(112,76,51)::"tram",rgb(237,179,140)::"bus",rgb(217,145,93)::"walk", rgb(244,169,160)::"other"];
	map<rgb,string> legend_path <- [rgb (car_color)::"car",rgb(bike_color)::"bike",rgb(tram_color)::"tram", rgb(people_color)::"people",rgb(bus_color)::"bus"];
	
    list<building> carpark_cbd;
	
	
	init {
		//create building
		create building from:shape_file_buildings with: [type::string(read ("type"))] ;
		list<building> residential_buildings <- building where (each.type="residential" /*or each.type="mixed"*/);
		list<building> industrial_buildings <- building  where (/*each.type="work" or*/ each.type="university" /*or each.type="mixed"*/) ;
		carpark_cbd <- building  where (each.type="residential" or each.type="mixed" or each.type="carpark");
		
		create outside_gates from:point_file_outside_cbd;
		create tramline from:shape_file_cbd_tram;
		create carline from:shape_file_cbd_car;
		
		
		create traffic_network from:shape_file_cbd_traffic with:[type::string(read ("highway"))]{
			if (type="tramway"){
				mode<-"tram";
			}
			if (type="driveway"){
				mode<-"car";
			}
			if (type="footway"){
				mode<-"people";
			}
		}
		
		
		ask traffic_network{
			if (type!="tramway" and type!="footway" and type!="driveway"){
				do die;
			}
		}
		//list<tramline> tramway <- tramline;
		tram_network_graph <- as_edge_graph (tramline);
		list<traffic_network> pedestrianway <- traffic_network where (each.type="footway");
		pedestrian_network_graph <- as_edge_graph (pedestrianway);
		list<traffic_network> bikeway <- traffic_network where (each.type="driveway");
		bike_network_graph <- as_edge_graph (bikeway);
		//list<traffic_network> carway <- traffic_network where (each.type="driveway");
		car_network_graph <- as_edge_graph (carline);
		

	
		
		
		//create people from the demographic file
		matrix data_people <- matrix(text_file_population);
		loop i from: 0 to: data_people.rows -1{
			create people number:int(data_people[1,i])/100{
				age_group <- int(i+1);
				speed <- float(data_people[2,i]);
				if(age_group=6){
					location <- any_location_in (one_of(outside_gates));
				} else {
					location <- any_location_in (one_of(residential_buildings));
				}
				taffic_mode<<+ [int(data_people[3,i]),int(data_people[4,i]),int(data_people[5,i]),int(data_people[6,i]),int(data_people[7,i])];
				start_work <- int(data_people[8,i]);
				end_work <- int(data_people[9,i]);
				living_place <- one_of(residential_buildings);
				working_place <- one_of(industrial_buildings);
				objective <- "resting";
			}
		}
		
		/*create people number:100{
			justwonder<-true;
			location <- any_location_in (one_of(building));
		}*/	
		

		create tram number:nb_tram {
			location<-any_location_in(one_of(tramline));
		// add loop break function to distribute tram

		}
		/*create bus number:nb_bus{
			location <- any_location_in (one_of(bus_network_graph));
		}*/

		/*create car number:nb_car{
			location<-any_location_in(one_of(carline));
		}*/
		//create car from the car file
		int ratio_of_car<-1000;
		matrix data_car <- matrix(text_file_car);
		loop i from: 0 to: data_car.rows -1{
			create car number: int(data_car[1,i])/ratio_of_car {
				car_group <- int(i+1);
				//location <- any_location_in (one_of(carpark_cbd));
				//location <- any_location_in (one_of(car_network_graph));
				
				/*if(car_group=1){
					location <- any_location_in (one_of(carpark_cbd));
					self.color<-#orange;
				} else {
					location <- any_location_in (one_of(outside_gates));
					self.color<-#pink;
				}*/
			}
		}
		
		
		create bike number:nb_bike;				
		create hack from:shape_file_hack;
	}
	
	reflex pollution_evolution {
		//ask all cells to decrease their level of pollution
		cell <- cell * 0.95;
		//diffuse the pollutions to neighbor cells
		diffuse var: pollution on: cell proportion: 0.9;
	}
	
	/*reflex updateCar{
		int car_group;
		ask 1 among car{
			car_group<-self.car_group;
			do die;
		}
		create car number: 1 {
		  if(car_group=1){
					location <- any_location_in (one_of(carpark_cbd));
					self.color<-#orange;
				} else {
					location <- any_location_in (one_of(outside_gates));
					self.color<-#pink;
				}
        }
	}*/

}

species building {
	string type; 
	rgb color;
	
	aspect base {
		draw shape color:building_color;
	}
	
	aspect landuse{
		draw shape color:(building_usage_color[type] = nil)? #black : building_usage_color[type];
	}
}

species building3D {
	float structure_; 
	rgb color;
	
	aspect base {
		draw shape color:rgb(255,255,255) border:#gray depth:((cycle>structure_) ?  structure_ : cycle);
	}
	
}


species traffic_network{
	string type;
	string mode;
	int path_group;
	
	//command display after right click
	user_command "change road type to car" action: change_type1;
	action change_type1{
	type <- "driveway";
	mode<-"car";
	
	}
	user_command "change road type to pedestrian" action: change_type2;
	action change_type2{
	type <- "footway";
	mode<-"people";
	}
	user_command "change road type to bike" action: change_type3;
	action change_type3{
	type <- "footway";
	mode<-"people";
	}
	user_command "change road type to tram" action: change_type4;
	action change_type4{
	type <- "tramway";
	mode<-"tram";
	}
	user_command "change road type to bus" action: change_type5;
	action change_type5{
	type <- "driveway";
	mode<-"car";
	}
	
	aspect base {
		draw shape color:path_type_color[mode] width:network_line_width;
	}
}

species tramline{
	aspect base {
		draw shape color:path_type_color["tram"] width:network_line_width;
	}
}

species carline{
	aspect base {
		draw shape color:path_type_color["car"] width:network_line_width;
	}
}
species outside_gates{
	aspect base{
		draw circle(100) color:#pink;
	}
}

species sensor{
	string name;
	aspect base {
		draw square(20) color:#black;
	}
}

species people skills:[moving] {
	rgb color <- #yellow ;
	building living_place <- nil ;
	building working_place <- nil ;
	int start_work ;
	int end_work  ;
	string objective ; 
	point the_target <- nil ;
	int age_group;
	list<int> taffic_mode;
	
	bool justwonder;
		
	reflex time_to_work when: current_date.hour = start_work and objective = "resting"{
		objective <- "working" ;
		the_target <- any_location_in (working_place);
	}
		
	reflex time_to_go_home when: current_date.hour = end_work and objective = "working"{
		objective <- "resting" ;
		the_target <- any_location_in (living_place); 
	} 
	 
	reflex move when: the_target != nil {
		do goto target: the_target  on: pedestrian_network_graph ; 
		if the_target = location {
			the_target <- nil ;
		}
	}
	
	reflex simplemove when:justwonder{
	  do wander;	
	}
	
	aspect base{
		draw circle(4) color: people_color ;
	}
	
	aspect age {
		draw circle(4) color: age_color[age_group] ;
	}
}

species tram skills:[moving] {
	int scale<-3;
	point target;
	float leaving_proba <- 1.0;
	init {
		//vehicle_length <- 33 #m;
		//max_speed <- 40 #km / #h;
		//max_acceleration <- 3.5;
	}
	
	/*reflex move when: (current_date.hour between(5,24) and simpleSimulation){
		  do wander on: tram_network_graph;	
	}*/
	
	reflex leave when: (target = nil) and (flip(leaving_proba) and  simpleSimulation) {
			target <- any_location_in(one_of(tram_network_graph));
	}
	
	reflex move when: (target != nil and simpleSimulation) {
		path path_followed <- goto(target: target, on: tram_network_graph, recompute_path: true, return_path: true);
	    if(length(path_followed.edges)=0){
			target <- any_location_in(one_of(tram_network_graph));
		}
   	    if (path_followed != nil and path_followed.shape != nil) {
			//cell[path_followed.shape.location] <- cell[path_followed.shape.location] + 10;					
		}

		if (location = target) {
			target <- nil;
		} 
	}

	aspect base {
		draw rectangle(20*scale, 3*scale) rotate: heading color: tram_color ;
		draw rectangle(10*scale, 3*scale) rotate: heading color: #white ;
	}
}

species car skills:[moving] {
	rgb color;
	int scale<-3;
	init {
		//vehicle_length <- 15#m ;
		//max_speed <- 40 #km / #h;
		//max_acceleration <- 3.5;
	}
	int car_group;
	point target;
	float leaving_proba <- 1.0;
	string state;
	
	reflex simpleMove when:!simpleSimulation{
		do wander on:car_network_graph;
	}
	
	reflex leave when: (target = nil) and (flip(leaving_proba) and  simpleSimulation) {
		target <- any_location_in(one_of(car_network_graph));
	}
	
	reflex move when: (target != nil and simpleSimulation) {
		path path_followed <- goto(target: target, on: car_network_graph, recompute_path: true, return_path: true);
	    if(length(path_followed.edges)=0){
			target <- any_location_in(one_of(car_network_graph));
		}
   	    if (path_followed != nil and path_followed.shape != nil) {
			cell[path_followed.shape.location] <- cell[path_followed.shape.location] + 10;					
		}

		if (location = target) {
			target <- nil;
		} 
	}
	

	aspect base {
		draw rectangle(5*scale, 2*scale) rotate: heading color:car_color ;
	}
}

species bike skills:[driving] {

	//Reflex to move to the target building moving on the road network
	reflex move when:simpleSimulation{
	do wander on:bike_network_graph;
	}

	aspect base {
		draw triangle(10) rotate: heading +90 color:bike_color ;
	}
}

species hack{
	aspect base{
		draw shape color:#black;
	}
}


experiment cbd_toolkit_virtual type: gui autorun:true virtual:true{	
	float minimum_cycle_duration<-0.05;
	output synchronized:true{
		
		display Screen1 type: 3d axes: false background:background_color virtual:true autosave:false {
			rotation angle:-21;
			
			//species building aspect: base visible:show_building ;
			species building aspect: landuse visible:show_landuse ;
			//species traffic_network aspect: base visible:show_network ;
			species carline aspect: base visible:show_network ;
		    species tramline aspect: base visible:show_network ;
			
			species people aspect: age visible:show_people ;
			species tram aspect: base visible:show_tram ;
			species car aspect: base visible:show_car ;
			species bike aspect: base visible:show_bike ;
			
			

			mesh cell scale: 9 triangulation: true transparency: 0.4 smooth: 3 above: 0.8 color: pal visible:show_heatmap;
			species hack aspect:base position:{0,0,0.001};
			
		
			event "l"  {show_landuse<-!show_landuse;}
			event "t"  {show_tram<-!show_tram;}
			event "c"  {show_car<-!show_car;}
			event "b"  {show_bike<-!show_bike;}
			event "n"  {show_network<-!show_network;}
			event "p"  {show_people<-!show_people;}
			event "h"  {show_heatmap<-!show_heatmap;}
			
			
			overlay position: { 50#px,50#px} size: { 1 #px, 1 #px } background: # black border: #black rounded: false
			{
	
				if(show_legend){
				//draw image_file('../includes/interface/cbdlogov1.png') at: { 200#px,50#px } size:{367.5#px,75#px};
				
				draw "Date: " + current_date at: {0,200#px} color: text_color font: font(myFont, 20, #bold);
				
                
                point UX_Position<-{world.shape.width*1.25,0#px};
                float x<-UX_Position.x;
                float y<-UX_Position.y;
        
                float gapBetweenWord<-25#px;
                float uxTextSize<-20.0;
                
                y<-y+gapBetweenWord;
                draw "(L)ANDUSE (" + show_landuse + ")" at: { x,y} color: text_color font: font(myFont, uxTextSize, #bold);
                y<-y+gapBetweenWord;
                y<-y+gapBetweenWord;
                draw "(P)EOPLE (" + show_people + ")" at: { x,y} color: text_color font: font(myFont, uxTextSize, #bold);
                y<-y+gapBetweenWord;
                draw "(T)RAM (" + show_tram + ")" at: { x,y} color: text_color font: font(myFont, uxTextSize, #bold);
                y<-y+gapBetweenWord;
                draw "(C)AR (" + show_car + ")" at: { x,y} color: text_color font: font(myFont, uxTextSize, #bold);
              //  y<-y+gapBetweenWord;
               // draw "B(U)S (" + show_bus + ")" at: { x,y} color: text_color font: font(myFont, uxTextSize, #bold);
                y<-y+gapBetweenWord;
                draw "(B)IKE (" + show_bike + ")" at: { x,y} color: text_color font: font(myFont, uxTextSize, #bold);
                y<-y+gapBetweenWord;
                draw "(N)ETWORK (" + show_network + ")" at: { x,y} color: text_color font: font(myFont, uxTextSize, #bold);
                y<-y+gapBetweenWord;
                
                /*y<-y+gapBetweenWord;
                draw "(S)ENSOR (" + show_sensor + ")" at: { x,y} color: text_color font: font(myFont, uxTextSize, #bold);
                y<-y+gapBetweenWord;*/
                draw "(H)EATMAP (" + show_heatmap + ")" at: { x,y} color: text_color font: font(myFont, uxTextSize, #bold);
                y<-y+gapBetweenWord;
                
                if(show_mode_legend){
                	draw "MODE" at: { 60#px, y} color: text_color  font: font(myFont, 30, #bold);
                	y <- y + 40#px;
	                    if(show_people){
	                	  draw circle(15#px) at: { 20#px, y} color: rgb(people_color, 0.8) ;
	                	  draw "people" at: { 60#px, y} color: rgb(people_color, 0.8)  font: font(myFont, 30, #bold);
	                	  draw string(length(people)) at: {175#px, y} color: rgb(people_color, 0.8)  font: font(myFont, 30, #bold);		
	                	}
	                	y <- y + 40#px;
	                	if(show_tram){
	                	  draw circle(15#px) at: { 20#px, y} color: rgb(tram_color, 0.8) ;
	                	  draw "tram" at: { 60#px, y} color: rgb(tram_color, 0.8)  font: font(myFont, 30, #bold);
	                	  draw string(length(tram)) at: {145#px, y} color: rgb(tram_color, 0.8)  font: font(myFont, 30, #bold);		
	                	}
	                	
	                	y <- y + 40#px;
	                	if(show_car){
	                	  draw circle(15#px) at: { 20#px, y} color: rgb(car_color, 0.8) ;
	                	  draw "car" at: { 60#px, y} color: rgb(car_color, 0.8)  font: font(myFont, 30, #bold);
	                	  draw string(length(car)) at: {135#px, y} color: rgb(car_color, 0.8)  font: font(myFont, 30, #bold);		
	                	}
	                	y <- y + 40#px;
	                	if(show_bike){
	                	  draw circle(15#px) at: { 20#px, y} color: rgb(bike_color, 0.8) ;
	                	  draw "bike" at: { 60#px, y} color: rgb(bike_color, 0.8)  font: font(myFont, 30, #bold);
	                	  draw string(length(bike)) at: {135#px, y} color: rgb(bike_color, 0.8)  font: font(myFont, 30, #bold);		
	                	}
	                	y <- y + 40#px;
                }
                
                
                if (show_landuse){
                	y <- y + 40#px;
                	draw "LANDUSE" at: { 60#px, y} color: text_color  font: font(myFont, 30, #bold);
                	y <- y + 40#px;
                	loop l over: building_usage_color.pairs
                    {
                	draw square(15#px) at: { 20#px, y} color: rgb(l.value, 0.8) ;
                	draw l.key at: { 60#px, y} color: rgb(l.value, 0.8)  font: font(myFont, 30, #bold);
                    y <- y + 40#px;
                    }
                	
                }
                
               
             
               
                
			}				
		  }
		
		}
		
		
		
		display Screen2 type: 2d virtual:true background:background_color antialias:false 
		{
			overlay position: { 50#px,50#px} size: { 1 #px, 1 #px } background: # black border: #black rounded: false
			{
			    draw "CBD ToolKIT v1.0" at: {0,0} color: text_color font: font(myFont, 50, #bold);
			    //draw image_file('../includes/interface/cbdlogov1.png') at: { 200#px, 25#px } size:{367.5#px,75#px};
			    
			    //draw "Date: " + current_date at: {0,250#px} color: text_color font: font(myFont, 20, #bold);
			}
			
			
			chart "Mode of Transport proportion" type: pie style: ring background: background_color color: rgb(236,102,45) label_text_color: rgb(236,102,45)  axes: #red  title_font: font( 'BrownPro', 32.0, #plain)
			tick_font: font('BrownPro' , 14, #plain) label_font: font('BrownPro', 32 #plain) x_label: 'Nice Xlabel' y_label:
			'Nice Ylabel' size:{0.42,0.42} position:{0,0.1}  label_background_color: background_color tick_line_color: rgb(255,255,255) memorize:false
			legend_font: font('BrownPro' , 14, #plain) 
			
			{
				data "Car" value: (length(car)) color: rgb(71,42,22);
				data "Tram" value: (length(tram)) color: rgb(112,76,51);
				data "Bike" value: (-1) color: rgb(161,106,69);
				data "Walk" value: (length(people)) color: rgb(217,145,93);
				data "Bus" value: (-1) color: rgb(237,179,140);
				data "Other" value:(-1) color: rgb(244,216,189);
				
			}
			
			chart "Pollution Level" type:histogram   size:{0.42,0.42} position:{0.55,0.1} background: background_color color: rgb(236,102,45)
			tick_font: font('BrownPro' , 14, #plain) label_text_color: rgb(236,102,45) title_font: font( 'BrownPro', 32.0, #plain) 
			label_font: font('BrownPro', 14 #plain) legend_font: font('BrownPro' , 14, #plain) memorize:false
			x_serie_labels: ["categ1","Mode of Transport"]
			style:"3d"
			series_label_position: xaxis
			{
				data "Walk" value:0
				accumulate_values: false						
			    color:rgb(217,145,93);
			    
				data "Bike" value: 0
				accumulate_values: false						
				color: rgb(161,106,69);
			    
				data "Tram" value:length(tram)*55
				accumulate_values: false						
				color: rgb(112,76,51);
				
				data "Car" value:(length(car))*270
				accumulate_values: false						
				color: rgb(71,42,22);

			}
			
			chart "Demography" type: pie style: ring background: background_color color: rgb(236,102,45) label_text_color: rgb(236,102,45)  axes: #red  title_font: font( 'BrownPro', 32.0, #plain)
			tick_font: font('BrownPro' , 14, #plain) label_font: font('BrownPro', 32 #plain) x_label: 'Nice Xlabel' y_label:
			'Nice Ylabel' size:{0.42,0.42} position:{0,0.55}  label_background_color: background_color tick_line_color: rgb(255,255,255) memorize:false
			legend_font: font('BrownPro' , 14, #plain) 
			
			{
				data "Age 0-14" value: (length(people)*0.034) color: rgb(71,42,22);
				data "Age 15-34" value: (length(people)*0.7) color: rgb(112,76,51);
				data "Age 35-64" value: (length(people)*0.23) color: rgb(161,106,69);
				data "Age 65-84" value: (length(people)*0.029) color: rgb(217,145,93);
				data "Above 85" value: (length(people)*0.007) color: rgb(237,179,140);
				data "Living outside cbd" value:(length(people)*0.5+cycle) color: rgb(244,216,189);
				
			}
			
			chart "Tree Canopy Coverage" type:histogram   size:{0.42,0.42} position:{0.55,0.55} background: background_color color: rgb(236,102,45)
			tick_font: font('BrownPro' , 14, #plain) label_text_color: rgb(236,102,45) title_font: font( 'BrownPro', 32.0, #plain) 
			label_font: font('BrownPro', 14 #plain)  legend_font: font('BrownPro' , 14, #plain) memorize:false
			x_serie_labels: ["categ1","Mode of Transport"]
			style:"3d"
			series_label_position: xaxis
			{
				data "1743" value:(80)
				accumulate_values: false						
			    color:rgb(217,145,93);
			    
				data "1900" value:(10)
				accumulate_values: false						
				color: rgb(161,106,69);
			    
				data "Now" value:(20)
				accumulate_values: false						
				color: rgb(112,76,51);
				
				data "Try it!" value:(0)
				accumulate_values: false						
				color: rgb(71,42,22);
				
				data "2040" value:(40)
				accumulate_values: false						
				color: rgb(244,216,189);
			}
		}
	}
}


experiment cbd_toolkit_desktop type: gui autorun:false parent:cbd_toolkit_virtual{	
	float minimum_cycle_duration<-0.01;
	output{
		display table parent:Screen1 {	
		}
	}
}




