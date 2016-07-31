// GLSL fragment shader
varying vec3 eyeSpacePos;
varying vec3 worldSpaceNormal;
varying vec3 eyeSpaceNormal;
varying float sgn;
varying float height;
varying float idx;


uniform float ttimer;
uniform vec4 deepColor;
uniform vec4 shallowColor;
uniform vec4 skyColor;
uniform vec3 lightDir;
varying vec3 sgn2;
void main()
{

    vec3 eyeVector              = normalize(eyeSpacePos);
    vec3 eyeSpaceNormalVector   = normalize(eyeSpaceNormal);
    vec3 worldSpaceNormalVector = normalize(worldSpaceNormal);
	float sign=sgn;
    float facing    = max(0.0, dot(eyeSpaceNormalVector, -eyeVector));
    float fresnel   = pow(1.0 - facing, 5.0); // Fresnel approximation
    float diffuse   = max(0.0, dot(worldSpaceNormalVector, lightDir));
    
    vec4 waterColor = mix(shallowColor, deepColor, facing);
    float zval=height;
    float myColor[3];
 
    
   if (zval < 0.2)
   
		{ myColor[0]=0.5*(1.0-zval/0.2);myColor[1]=0.0;myColor[2]=0.5+(0.5*zval/0.2);}
		
	zval*=4.2;
	
	if ((zval >= 0.2) && (zval < 0.40))	// blue to cyan ramp
		{ myColor[0]= 0.0; myColor[1]= (zval-0.2)*5.0; myColor[2] = 1.0; }
	if ((zval >= 0.40) && (zval < 0.6))	// cyan to green ramp
		{ myColor[0]= 0.0; myColor[1]= 1.0; myColor[2] = (0.6-zval)*5.0; }
	if ((zval >= 0.6) && (zval < 0.8))	// green to yellow ramp
		{ myColor[0]= (zval-0.6)*5.0; myColor[1]= 1.0; myColor[2] = 0.0; }
	if (zval >= 0.8)	// yellow to red ramp
		{ myColor[0]= 1.0; myColor[1]= (1.0-zval)*5.0; myColor[2]= 0.0; }

		vec4 color1 = skyColor*fresnel;
		vec4 color2 = waterColor*diffuse ;
		vec4 color;

	
	color=color1+color2;// - vec4(-(4.0-zval)/40.0,-(4.0-zval)/40.0,zval/10.0,0.5);

	
	if(idx>19742.0)
		color=vec4(0.8,0.5,0.5,0.5);
		
	if(idx>19766.0)
		color=vec4(0.2,0.1,0.2,0.5);
	if(idx>19772.0)
		color=vec4(0.3,0.1,0.2,0.5);

    	gl_FragColor = color;
  
    	
    
}
