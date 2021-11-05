shader_type canvas_item;

uniform sampler2D raw_texture;
uniform sampler2D sel_texture;

void fragment() {
	vec4 clr = texture(sel_texture, UV);
    COLOR = texture(raw_texture, UV);
    if (clr.r==1.0 && (fract(UV.x*32.0)<0.07 || fract(UV.y*48.0)<0.07 || fract(UV.x*32.0)>0.93 || fract(UV.y*48.0)>0.93)){
        if (length(COLOR.rgb)>0.5){
            COLOR = vec4(0,0,0,1);
        }else{
            COLOR = vec4(1,1,1,1);
        }
    }
    
	    
}