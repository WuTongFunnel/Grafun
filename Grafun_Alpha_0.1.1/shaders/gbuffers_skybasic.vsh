#version 450 compatibility

out vec4 glcolor;
void main() {
		vec4 pos = gl_Vertex;
	gl_Position = gl_ModelViewProjectionMatrix * pos;
	glcolor = gl_Color;
}
