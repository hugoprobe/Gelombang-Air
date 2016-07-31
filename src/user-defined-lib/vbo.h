#ifndef VBO_H_
#define VBO_H_

#include <GL/glew.h>

#include <cuda_gl_interop.h>
#include <helper_functions.h>    // includes cuda.h and cuda_runtime_api.h


// CUDA helper functions
#include <helper_cuda.h>         // helper functions for CUDA error check
#include <helper_cuda_gl.h>

void createVBO2(GLuint *vbo, int size);
void deleteVBO2(GLuint *vbo);


#endif /* VBO_H_ */
