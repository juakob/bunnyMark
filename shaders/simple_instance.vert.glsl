#version 450

in vec2 vertexPosition;
in vec4 uv;
in vec3 scaleXRotxMovX;
in vec3 scaleYRotYMovY;

uniform mat4 projectionMatrix;
out vec2 texCoord;


void kore() {
	float x =vertexPosition.x*scaleXRotxMovX.x+scaleXRotxMovX.z;
	float y =vertexPosition.y*scaleYRotYMovY.x+scaleYRotYMovY.z;
	gl_Position =  projectionMatrix*vec4(x,y,0.0, 1.0) ;
	texCoord = vec2(vertexPosition.x*uv.z+uv.x,vertexPosition.y*uv.w+uv.y);

}
