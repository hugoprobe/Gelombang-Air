#include "vbo.h"

void createVBO2(GLuint *vbo, int size)
{

    glGenBuffers(1, vbo);
    glBindBuffer(GL_ARRAY_BUFFER, *vbo);
    glBufferData(GL_ARRAY_BUFFER, size, 0, GL_DYNAMIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);


    SDK_CHECK_ERROR_GL();
}


void deleteVBO2(GLuint *vbo)
{
    glDeleteBuffers(1, vbo);
    *vbo = 0;
}
