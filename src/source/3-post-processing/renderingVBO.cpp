#include "../../header/header.h"


int ttt=0;
double elapsed_time=0.0;

void renderingVBO(GLuint shaderProg, vbo VBO, dataWaveCompute dataDev, parameter Param)
{
  glEnable(GL_DEPTH_TEST);
	//render dari VBO
  glBindBuffer(GL_ARRAY_BUFFER, VBO.posVertexBuffer);
   glVertexPointer(4, GL_FLOAT, 0, 0);
   glEnableClientState(GL_VERTEX_ARRAY);


 glBindBuffer(GL_ARRAY_BUFFER, VBO.VertexNormalBuffer);
	glClientActiveTexture(GL_TEXTURE0);
	glTexCoordPointer(3, GL_FLOAT, 0, 0);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);

 glBindBuffer(GL_ARRAY_BUFFER, VBO.signBuffer);
	glClientActiveTexture(GL_TEXTURE1);
	glTexCoordPointer(1, GL_FLOAT, 0, 0);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);



  glUseProgram(shaderProg);

	// Set default uniform variables parameters for the vertex shader
	GLuint ttimer;
	ttt=(ttt+1)%255;
	ttimer = glGetUniformLocation(shaderProg, "ttimer");
	glUniform1f(ttimer, (ttt/255.0));


	// Set default uniform variables parameters for the pixel shader
	GLuint uniDeepColor, uniShallowColor, uniSkyColor, uniLightDir;

	uniDeepColor = glGetUniformLocation(shaderProg, "deepColor");
	glUniform4f(uniDeepColor, 0.0f, 0.1f, 0.4f, 1.0f);

	uniShallowColor = glGetUniformLocation(shaderProg, "shallowColor");
	glUniform4f(uniShallowColor, 0.1f, 0.3f, 0.3f, 1.0f);

	uniSkyColor = glGetUniformLocation(shaderProg, "skyColor");
	glUniform4f(uniSkyColor, 1.0f, 0.75f, 0.25f, 1.0f);

	uniLightDir = glGetUniformLocation(shaderProg, "lightDir");
	glUniform3f(uniLightDir, 0.0f, 1.0f, 0.0f);

	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, VBO.indexBuffer);

	if(Param.style==STYLE_WIRE)
	{
		glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
	}else
		glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);

		glDrawElements(GL_TRIANGLES, dataDev.Mesh.NCells*3+dataDev.Mesh.Wall.count*6, GL_UNSIGNED_INT, 0);
		glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
   glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);


   glDisableClientState(GL_VERTEX_ARRAY);
	glClientActiveTexture(GL_TEXTURE0);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glClientActiveTexture(GL_TEXTURE1);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisable (GL_BLEND);

	 glUseProgram(0);


}
