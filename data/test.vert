// GLSL vertex shader

varying vec3 worldSpaceNormal;
varying vec3 eyeSpaceNormal;
varying vec3 eyeSpacePos;
varying float sgn;
varying float height;
varying float idx;

void main()
{
   	float3  normal      = gl_MultiTexCoord0.xyz;
	float  sign      		= gl_MultiTexCoord1.x;
    worldSpaceNormal = normalize(vec3(normal.x,normal.y,normal.z));
   	sgn=sign;
  	vec4 pos;
	pos  = vec4(gl_Vertex.x, gl_Vertex.y, gl_Vertex.z, 1.0);
	height = gl_Vertex.y;
	idx=gl_VertexID;
	 gl_Position      = gl_ModelViewProjectionMatrix * pos;
      eyeSpacePos      = (gl_ModelViewMatrix * pos).xyz;
     eyeSpaceNormal   = (gl_NormalMatrix * worldSpaceNormal).xyz;
  }
