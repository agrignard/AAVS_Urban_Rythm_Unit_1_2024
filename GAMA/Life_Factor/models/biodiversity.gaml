/**
* Name: Life
* Based on the internal empty template. 
* Author: arno
* Tags: 
*/


model Life_Biodiversity

/* Insert your model definition here */

global{
	file cbd_bird_entrance <- file("../includes/GIS/microclimate/Biodiversity/biodiversity_bird_entrancepoint.shp");
	file cbd_bird_path <- file("../includes/GIS/microclimate/Biodiversity/biodiversity_bird_migration.shp");
	graph bird_channel;	
	int bird_population<-1000;
    file cbd_green <- file("../includes/GIS/cbd_green.shp");
	bool show_bird<-false;
	bool show_bird_gate<-false;
	bool show_green<-false;
	bool show_tree<-false;
	

	
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



species green{
	string type;
	aspect base {
		draw shape color:#green border:#black;
	}
}



