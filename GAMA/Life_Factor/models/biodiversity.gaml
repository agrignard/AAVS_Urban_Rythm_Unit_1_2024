/**
* Name: Life
* Based on the internal empty template. 
* Author: arno
* Tags: 
*/


model Life_Biodiversity
import "./parameters.gaml"
/* Insert your model definition here */

global{
	file cbd_bird_entrance <- file("../includes/GIS/microclimate/Biodiversity/biodiversity_bird_entrancepoint.shp");
	file cbd_bird_path <- file("../includes/GIS/microclimate/Biodiversity/biodiversity_bird_migration.shp");
	graph bird_channel;	
	int bird_population<-1000;
    file cbd_green <- file("../includes/GIS/cbd_green.shp");
    file shape_file_trees <- file("../includes/GIS/cbd_trees.shp");
    
	bool show_bird<-false;
	bool show_bird_gate<-false;
	bool show_green<-false;
	bool show_tree<-false;
	bool show_tree_family<-false;
	
	map<string,rgb> uselif_color<-["61+ years"::rgb(1,40,33), "31-60 years"::rgb(1,75,62), "21-30 years"::rgb(0,104,86), "11-20 years"::rgb(0,135,111), 
    "6-10 years (>50% canopy)"::rgb(0,195,160), "6-10 years (<50% canopy)"::rgb(30,233,182),"1-5 years (<50% canopy)"::rgb(0,255,209),"<1 year"::rgb(173,250,240),''::rgb(255,255,255)];
    map<string,rgb> group_to_color<- ["1"::rgb(142,198,63) ,"2"::rgb(231,192,52) , "3"::rgb(244,154,182) ,"4"::rgb(93,40,118)];
	rgb tree_color<-rgb(0,255,209);
	map<string,string> family_int_to_group<- ["1"::"Broadleaf Trees ","2"::"Coniferous Trees ", "3"::"Palm and Tropical Trees ","4"::"Flower Trees "];
 
	
	

	
	action initBiodiversityModel{
	   create green from: cbd_green ;
	   create bird_gate from:cbd_bird_entrance with: [targets:string(read ("targets"))]{
			self.shape<-circle(100) at_location self.location;
			myTargets<-(targets split_with ',');
		}
	   create bird_path from:cbd_bird_path;
	   bird_channel <- as_edge_graph(cbd_bird_path);
	}
	
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
		draw triangle(20) rotate: heading+90 color:hungry ? #purple : (full ? model_color["bio_green"] : model_color["bio_red"]) border:#black;
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



species green{
	string type;
	aspect base {
		draw shape color:#green border:#black;
	}
}


species tree{
	rgb color;
	string family;
	int year_plant;
	int diameter_b;
	string useful_lif;
	string group;
	
	
	aspect base{
		if(cycle+1899>year_plant){
			draw circle(10) color:tree_color;
		}
		
	}
	
	aspect useful_lif{
	   draw circle(5+diameter_b*0.25) color:uselif_color[useful_lif];
	}
	aspect family{
		if (family !=nil){
		  draw circle(5+diameter_b*0.25) color:group_to_color[group];	
		}
	}
}



