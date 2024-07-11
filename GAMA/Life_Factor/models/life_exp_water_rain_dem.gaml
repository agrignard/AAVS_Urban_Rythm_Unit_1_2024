/**
* Name: Water flowing in the red river bed
* Author: drogoul
* Tags: 
*/


model Terrain

global parent: physical_world {
	bool use_native <- true;
	// We scale the DEM up a little
	float z_scale <- 0.5;
	float step <-  1.0/30;	
	bool flowing <- true;
	point gravity <- {-z_scale/4, z_scale, -9.81};
	int number_of_water_units <- 1 min: 0 max: 10;
	list<point> origins_of_flow <- [{17,3}, {55,3}];
	field terrain <- field(grid_file("../includes/GIS/cbd_dem.asc"));
    file cbd_buildings <- file("../includes/GIS/cbd_buildings.shp");
	geometry shape <- box({terrain.columns, terrain.rows, max(terrain)*z_scale});
	float friction <- 0.0;
	float restitution <- 0.5;


	init {
		create building from: cbd_buildings;
		do register([self]);
	}

	reflex flow {
			loop origin_of_flow over: origins_of_flow {
				int x <- int(min(terrain.columns - 1, max(0, origin_of_flow.x + rnd(10) - 5)));
				int y <- int(min(terrain.rows - 1, max(0, origin_of_flow.y + rnd(10) - 5)));
				point p <- origin_of_flow + {rnd(10) - 5, rnd(10 - 5), terrain[x, y] + 4};
				p<-any_location_in(shape);
				p<-{p.x,p.y,shape.width};
				create water number: number_of_water_units with: [location::p];
			}
	}
}

species water skills: [dynamic_body] {
	geometry shape <- sphere(0.5);
	float friction <- 0.1;
	float damping <- 0.1;
	float mass <- 0.1;
	rgb color <- one_of(brewer_colors("Blues"));
	

	aspect default {
		if (location.y > 10){
		draw shape color: color;}
	}
	
		
	reflex manage_location when: location.z < -20 {
		do die;
	}

} 

species building{
	aspect base{
		draw shape color:#gray;
	}
}


experiment "Rain" type: gui {
	
	string camera_loc <- #from_up_front;
	int distance <- 200;
	
	action _init_ {
		create simulation with: [z_scale::0.03];
	} 
	
	output {
		layout #split;
		display "Flow" type: 3d background: #white   antialias: false camera: #from_up_front{
			mesh terrain grayscale: true triangulation: true refresh: false scale: z_scale;
			species building aspect:base;
			species water;
		}

	}}
	