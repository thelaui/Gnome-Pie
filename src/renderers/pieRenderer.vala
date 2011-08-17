/* 
Copyright (c) 2011 by Simon Schneegans

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>. 
*/

using GLib.Math;

namespace GnomePie {

public class PieRenderer {

    public int quick_action {get; private set;}
    public int active_slice {get; private set;}

    private int size;
    private Gee.ArrayList<SliceRenderer?> slices;
    private CenterRenderer center;
    
    public PieRenderer() {
        this.slices = new Gee.ArrayList<SliceRenderer?>(); 
        this.center = new CenterRenderer(this);
        this.quick_action = -1;
        this.active_slice = -1;
        this.size = 0;
    }
    
    public void load_pie(Pie pie) {
    
        this.slices.clear();
        
        this.quick_action = pie.quick_action;
        this.active_slice = pie.quick_action;
    
        foreach (var group in pie.action_groups) {
            foreach (var action in group.actions) {
                var renderer = new SliceRenderer(this);
                this.slices.add(renderer);
                renderer.load(action, slices.size-1);
            }
        }
        
        if(this.quick_action >= 0 && this.quick_action < this.slices.size) {
            this.center.set_active_slice(this.slices[this.quick_action]);
            
            foreach (var slice in this.slices)
		        slice.set_active_slice(this.slices[this.quick_action]);
        }
        
        this.size = (int)fmax(
                        (((Config.global.theme.slice_radius
                         + Config.global.theme.slice_gap)/tan(PI/slices.size)) 
                         + Config.global.theme.slice_radius)*2*Config.global.theme.max_zoom,
                        fmax(
                              2*Config.global.theme.radius + 2*Config.global.theme.slice_radius*Config.global.theme.max_zoom,
                              2*Config.global.theme.center_radius
                        )
                    );
    }
    
    public void activate() {
        if (this.active_slice >= 0 && this.active_slice < this.slices.size)
            slices[active_slice].activate();
        this.cancel();
    }
    
    public void cancel() {
        foreach (var slice in this.slices)
            slice.fade_out();
            
        center.fade_out();
    }
    
    public int slice_count() {
        return slices.size;
    }
    
    public int get_size() {
        return size;
    }
    
    public void draw(Cairo.Context ctx, int mouse_x, int mouse_y) {
	    double distance = sqrt(mouse_x*mouse_x + mouse_y*mouse_y);
	    double angle = 0.0;
	
	    if (distance > 0) {
	        angle = acos(mouse_x/distance);
		    if (mouse_y < 0) 
		        angle = 2*PI - angle;
	    }
	    
	    int next_active_slice = this.active_slice;
	    
	    if (distance < Config.global.theme.active_radius
	        && this.quick_action >= 0 && this.quick_action < this.slices.size) {
	     
	        next_active_slice = this.quick_action;   
	        angle = 2.0*PI*quick_action/(double)slice_count();
	    } else if (distance > Config.global.theme.active_radius) {
	        next_active_slice = (int)(angle*slices.size/(2*PI) + 0.5) % this.slice_count();
	    } else {
	        next_active_slice = -1;
	    }
	    
	    if (next_active_slice != this.active_slice) {
	        this.active_slice = next_active_slice;
	        
	        SliceRenderer? active = ((this.active_slice >= 0 && this.active_slice < this.slice_count()) ?
	                                  this.slices[this.active_slice] : null);
	                                  
	        center.set_active_slice(active);
	        
	        foreach (var slice in this.slices)
		        slice.set_active_slice(active);
	    }

        center.draw(ctx, angle, distance);
	    
	    foreach (var slice in this.slices)
		    slice.draw(ctx, angle, distance);
    }
}

}
