/**
* Name: Life
* Based on the internal empty template. 
* Author: arno
* Tags: 
*/


model Life

import './parameters.gaml'
import './shadow.gaml'
import "./water.gaml"
import "./wind.gaml"
import "./biodiversity.gaml"

global{
		
	geometry shape <- envelope(shape_file_bounds);
	bool show_all_scenario<-true;
	bool show_scenario_1<-false;
	bool show_scenario_2<-false;
	bool show_scenario_3<-false;
	
	
	bool show_landuse<-false;
	bool show_heritage<-false;
    bool show_water_model<-false;
    bool show_instant_water_heatmap<-false;
    bool show_aggregated_water_heatmap<-false;
    bool show_shadow_model<-false;
	bool show_wind_model<-false;
	bool show_biodiversity_model<-true;
	bool show_tree_family<-false;
	bool show_tree_lifespan<-true;
	
	bool show_legend<-false;
	bool show_wind_legend<-false;
	bool show_water_legend<-false;
	bool show_tree_family_legend<-false;
	bool show_tree_lifespan_legend<-false;
	bool show_bird_legend<-true;
	bool show_bird_family_legend<-false;
	rgb text_color<-rgb(255,255,255);
	string myFont;
	
	//float step <- 0.5 #sec;
	date starting_date <- date([2024,10,1,6,0,0]);
	
	init{
		create border from: shape_file_bounds ;		
		create building from: cbd_buildings with: [type::string(read ("predominan")),depth::int(read ("structur_1"))] ;
		create heritage_building from: cbd_buildings_heritage with: [type::string(read ("HERIT_OBJ"))] ;	
	    create proposal from: cbd_proposals with: [type::string(read ("type")),name::string(read ("name")),height::float(read ("height"))] ;
		create tree from: shape_file_trees{
			shape<-circle(10);
		}
		list<string> families <- remove_duplicates(tree collect each.family);		
		do initShadowModel;
		do initWaterModel;
		do triggerWaterModel(show_water_model);
		do initWindModel(cbd_buildings);
		do triggerWindModel(show_wind_model);
	    do initBiodiversityModel();
	    do triggerBiodiversityModel(show_biodiversity_model);
	    if(show_all_scenario){
	    	do createAllScenarios;
	    }
	}
	
	action createAllScenarios{
		do createScenario("Abeckett");
		do createScenario("China Town");
		do createScenario("Parliament");
	}

	//CREATE SCENARIO
	action createScenario(string _name){
		ask proposal where (each.name=_name and each.type="Green"){
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
	

	action triggerWindModel (bool value){
       show_global_wind_flow<-value;
       show_global_wind_point<-value;
	   show_windy_building<-value;
       show_local_wind_particle<-value;
	}
	
	action triggerBiodiversityModel (bool value){
	    show_bird<-value;
	    show_bird_gate<-value;
	    show_green<-value;
	    //show_tree<-value;
	}
}

experiment life type: gui autorun:false{
	init{
	  gama.pref_display_numkeyscam<-false;		
	}	
	output synchronized:true{
		display city_display type:3d fullscreen:false background:#black axes:false autosave:false{
			rotation angle:-21;
			species border aspect:base ;
			species windy_building aspect:base visible:show_windy_building position:{0,0,0.1};
		
			species building aspect:wireframe_wind visible:show_landuse transparency:0.95;
			species heritage_building aspect:base visible:show_heritage;
			species shadow aspect:base visible:show_shadow;

			
			//mesh instant_water_heatmap scale: 0 color: palette([ #black, model_color["water"]]) smooth: 3 visible:show_instant_water_heatmap;
	        mesh history_water_heatmap scale: 0.01 color: gradient([ #black, model_color["water"]]) transparency: 0.2 smooth:3 visible:show_aggregated_water_heatmap;
			species waste_water_channel aspect:base visible:show_water_channel;
			species poi aspect:base visible:show_poi;
			species water aspect:base visible:show_water;
		
			species wind_avgspeed aspect:base  visible:show_avgwindspeed;
			species windborder aspect:base  visible:show_windborder;
			//species global_wind_point aspect:base position:{0,0,0.01} visible:show_global_wind_point;
			species global_wind_flow aspect:base position:{0,0,0} trace:5 fading:true visible:show_global_wind_flow;
			species wind_avgdirection aspect:base  visible:show_avgwinddirection position:{0,0,0.0};
			species windy_building aspect:base visible:show_windy_building position:{0,0,0.1};
			species windparticle aspect:abstract position:{0,0,0.0} trace:5 fading:true visible:show_local_wind_particle;
			
			species bird_gate aspect:base position:{0,0,0.01} visible:show_bird_gate;	
			species bird aspect:base  position:{0,0,0.01} visible:show_bird;
		
			species tree aspect: useful_lif visible:show_tree_lifespan transparency:0.8;
		    species tree aspect: family visible:show_tree_family;
			species green aspect:base visible:show_green;
			
		
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
			event "3"  {show_wind_model<-!show_wind_model;
				if(show_wind_model){
				  ask simulation{do triggerWindModel(true);}
				}else{
				  ask simulation{do triggerWindModel(false);}
				}
				
				
			}
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
			event "b"  {show_bird<-!show_bird;}
			event "g"  {show_green<-!show_green;}
			event "f"  {show_tree_family<-!show_tree_family;}
			
			overlay position: { 50#px,50#px} size: { 1 #px, 1 #px } background: # black border: #black rounded: false
			{   
				//draw "UNIT 1 - URBAN RHYTHMS" at: {0,200#px} color: text_color font: font(myFont, 30, #bold);
				
				point UX_Position<-{100#px,200#px};
                float x<-UX_Position.x;
                float y<-UX_Position.y;
                float gapBetweenWord<-25#px;
                float tabGap<-25#px;
                float uxTextSize<-30.0;	
                float x_offset<-10#px;
                float episodeTitleY<-300#px;
	            //draw string(current_date+6#hour+cycle*10#mn-cycle) at: {0,1300#px} color: text_color font: font(myFont, uxTextSize*1.5, #bold);
	            draw string(current_date+6#hour) at: {0,1300#px} color: text_color font: font(myFont, uxTextSize*1.5, #bold);
				if(show_legend){
					draw image_file('../images/life.png') at: { 200#px,50#px } size:{120#px,84#px};
	               
	                
	                draw "(1) SHADOW MODEL(" + show_shadow_model + ")" at: { x,y} color: model_color["shadow"] font: font(myFont, uxTextSize, #bold);
	                if(show_shadow_model){
	                	 y<-y+gapBetweenWord;
	                	 draw "S(H)ADOW (" + show_shadow + ")" at: { x+tabGap,y} color: model_color["shadow"] font: font(myFont, uxTextSize, #bold);
	                }
	                y<-y+gapBetweenWord;
	                y<-y+gapBetweenWord;
	                draw "(2) WATER MODEL(" + show_water_model + ")" at: { x,y} color: model_color["water"] font: font(myFont, uxTextSize, #bold);
	                if(show_water_model){
	                	 y<-y+gapBetweenWord;
	                	 draw "WATER (C)HANNEL (" + show_water_channel + ")" at: { x+tabGap,y} color:  model_color["water"] font: font(myFont, uxTextSize, #bold);
	                	 y<-y+gapBetweenWord;
	                	 draw "(P)RODUCER (" + show_poi + ")" at: { x+tabGap,y} color:  model_color["water"] font: font(myFont, uxTextSize, #bold);
	                	 y<-y+gapBetweenWord;
	                	 draw "(W)ATER (" + show_water + ")" at: { x+tabGap,y} color:  model_color["water"] font: font(myFont, uxTextSize, #bold);
	                }
	                y<-y+gapBetweenWord;
	                y<-y+gapBetweenWord;
	                draw "(3) WIND MODEL (" + show_wind_model + ")" at: { x,y} color:  model_color["wind"] font: font(myFont, uxTextSize, #bold);
	                y<-y+gapBetweenWord;
	                y<-y+gapBetweenWord;
	                draw "(4) BIODIVERSITY MODEL(" + show_biodiversity_model + ")" at: { x,y} color: model_color["biodiversity"] font: font(myFont, uxTextSize, #bold);
	               
	                if(show_biodiversity_model){
	                	y<-y+gapBetweenWord;
	                	draw "(T)REE (" + show_tree + ")" at: { x+tabGap,y} color: model_color["biodiversity"] font: font(myFont, uxTextSize, #bold);
	                	y<-y+gapBetweenWord;
	                	draw "TREE (F)AMILY (" + show_tree_family + ")" at: { x+tabGap,y} color: model_color["biodiversity"] font: font(myFont, uxTextSize, #bold);
	                	y<-y+gapBetweenWord;

	                	draw "(G)REEN (" + show_green + ")" at: { x+tabGap,y} color: model_color["biodiversity"] font: font(myFont, uxTextSize, #bold);
		                y<-y+gapBetweenWord;
		                draw "(B)IRD (" + show_bird + ")" at: { x+tabGap,y} color: model_color["biodiversity"] font: font(myFont, uxTextSize, #bold);
		                
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
			    if(show_water_legend){
	                	y<-episodeTitleY;
	                	draw "FLOOD RISK" at: {0, y} color: text_color font: font(myFont, uxTextSize*1.5, #bold);
	                	y <- y + uxTextSize*3;
	                	int tmp<-length(water);
	                	draw circle(10#px) at: { 0, y } color: model_color["water"];
		                draw "WATER PARTICLE: " + tmp at: { 20#px, y + 8#px } color:text_color font: font(myFont, uxTextSize, #bold);
	            }		     
			    if(show_wind_legend){
	                	y<-episodeTitleY;
	                	draw "WIND TUNNEL" at: { 60#px, y} color: text_color font: font(myFont, uxTextSize*1.5, #bold);
	                	y <- y + uxTextSize*3;
	                	draw rectangle(5#px,30#px) at: { 20#px, y }  color:model_color["global_wind"];
	                	draw triangle(30#px) at: { 20#px, y } color: model_color["global_wind"];
		                draw "GLOBAL WIND"at: { 40#px, y + 4#px } color:text_color font: font(myFont, uxTextSize, #bold);
		                y <- y + uxTextSize*2;
		                draw triangle(30#px) at: { 20#px, y } color: model_color["wind"];
		                draw "LOCAL WIND"at: { 40#px, y + 4#px } color:text_color font: font(myFont, uxTextSize, #bold);
	            }	     
			    if(show_tree_family_legend){	     
			    	     y<-episodeTitleY;
	                	 draw "TREE SPECIES" at: { 60#px, y} color: text_color font: font(myFont, uxTextSize*1.5, #bold);
	            		//for each possible type, we draw a square with the corresponding color and we write the name of the type
	   					y <- y + 40#px;
		                loop g over: group_to_color.keys
		                {
		                    draw circle(10#px) at: { 20#px, y } color: group_to_color[g] border: #white;
		                    draw family_int_to_group[g] at: {40#px, y + 4#px } color: text_color font: font(myFont, uxTextSize, #bold);
		                     y <- y + uxTextSize*2;
		               }
		                
		         }
		         if(show_tree_lifespan_legend){
		                	
	                	y<-episodeTitleY;
	                	draw "TREE LIFESPAN" at: { 60#px, y} color: text_color font: font(myFont, uxTextSize*1.5, #bold);
	                	y <- y + 40#px;
		            	//for each possible type, we draw a square with the corresponding color and we write the name of the type
		                loop type over: uselif_color.keys
		                {
		                    
		                    if(type=''){
		                     draw circle(10#px) at: { 20#px, y } color: uselif_color[type] border: #white;
		                     draw "Unknown" at: { 40#px, y + 4#px } color:text_color font: font(myFont, uxTextSize, #bold);
		                     y <- y + 25#px;	
		                    }else{
		                    	draw circle(10#px) at: { 20#px, y } color: uselif_color[type] border: #white;
		                        draw type at: { 40#px, y + 4#px } color:text_color font: font(myFont, uxTextSize*0.95, #bold);
		                          y <- y + uxTextSize*2;
		                    }
		                    
		                }
	                }
	                if(show_bird_legend){
	                	y<-episodeTitleY;
	                	draw "BIODIVERSITY" at: { 60#px, y} color: text_color font: font(myFont, uxTextSize*1.5, #bold);
	                	y <- y + uxTextSize*3;
	                	draw triangle(30#px) at: { 20#px, y } color: model_color["bio_red"];
	                	//int tmp<-length(bird where (each.hungry=false));
		                draw "MIGRATING BIRD"at: { 40#px, y + 4#px } color:text_color font: font(myFont, uxTextSize, #bold);
		                y <- y + uxTextSize*2;
		                draw triangle(30#px) at: { 20#px, y } color: model_color["bio_purple"];
		               // tmp<-length(bird where (each.hungry=true));
		                draw "MIGRATING BIRD (eating)" at: { 40#px, y + 4#px } color:text_color font: font(myFont, uxTextSize, #bold);
	                    y <- y + uxTextSize*2;
	                    draw triangle(30#px) at: { 20#px, y } color: model_color["bio_green"];
		                //tmp<-length(bird where (each.full=true));
		                draw "MIGRATING BIRD (full)"  at: { 40#px, y + 4#px } color:text_color font: font(myFont, uxTextSize, #bold);
	
	                }
	                if(show_bird_family_legend){	
	                	y<-episodeTitleY;
	                	draw "BIODIVERSITY" at: { 60#px, y} color: text_color font: font(myFont, uxTextSize*1.5, #bold);
	                	y <- y + 40#px;
		            	//for each possible type, we draw a square with the corresponding color and we write the name of the type
		                loop type over: bird_color.keys
		                {
		                    	draw circle(12#px) at: { 20#px, y } color: bird_color[type] border: #white;
		                        draw type at: { 40#px, y + 8#px } color:text_color font: font(myFont, uxTextSize, #bold);
		                        y <- y + 30#px;
		                    
		                    
		                }
	                }	
	            			
		  }
		}
	}
}