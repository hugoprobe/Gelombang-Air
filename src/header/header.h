

#ifndef HEADER_H_
#define HEADER_H_

#include <X11/Xlib.h>



// OpenGL Graphics includes
#include <GL/glew.h>

#include <GL/freeglut.h>


#include <sys/time.h>
#include "analysis.h"
#include "../user defined lib/mesh.h"
#include "../user defined lib/cutil_math.h"

#include <vector_types.h>
// includes, cuda
#include <cuda_runtime.h>
#include <cuda_gl_interop.h>

// Utilities and timing functions
#include <helper_functions.h>    // includes cuda.h and cuda_runtime_api.h


// CUDA helper functions
#include <helper_cuda.h>         // helper functions for CUDA error check
#include <helper_cuda_gl.h>      // helper functions for CUDA/GL interop

#define g 9.8

#define MAX(a,b) ((a > b) ? a : b)

#define PAUSE 0
#define RUNNING 1

#define DEVICE_GPU 1
#define DEVICE_CPU 0
#define STYLE_NOVISUALIZATION 0
#define STYLE_SURFACE 1
#define STYLE_WIRE 2
#define STYLE_COLORHSV 3
#define TRUE 1
#define FALSE 0

typedef struct{				// Data-data komputasi yang diperlukan
	double *hnew, *unew, *vnew, *hunew, *hvnew;
	double *h, *u, *v, *hu, *hv,*z;
	double dt;
	mesh Mesh;

}dataWaveCompute;

typedef struct{
	GLuint
		posVertexBuffer,
		indexBuffer,
		VertexNormalBuffer,

		signBuffer;

	struct cudaGraphicsResource
					*cuda_VertexWall_resource,
					*cuda_VertexPos_resource,
					*cuda_VertexNormal_resource,
					*cuda_Sign_resource; // handles OpenGL-CUDA exchange
}vbo;



typedef struct{
	dim3 block;
	dim3 grid1;
	dim3 grid2;
}gpuThread;

typedef struct
{
	float4 *dptr;
	float3 *nptr;
	float *sptr;


}vboPointer;


// Initial Mesh
int InitMesh(mesh * Mesh, char *title);

//initial condition
int InitDataComputation(dataWaveCompute *data,double dt);


//Allocation Memory
double GPUSimulationAllocationMemory(dataWaveCompute *dataDev, dataWaveCompute dataHost);
int threadAllocation(int blockAllocation, gpuThread *GPUThread, dataWaveCompute dataDev);

//init vbo

void initVBO(vbo *VBO, mesh Mesh);


//Processing
double computeGPU(int iteration , gpuThread GPUThread,   dataWaveCompute *dataDev);
double computeCPU(int iteration, dataWaveCompute  *dataHost);

//Post Processing
void computeVisualization(vbo VBO,  parameter Param, gpuThread  GPUThread,  dataWaveCompute *dataDev, dataWaveCompute dataHost);
void renderingVBO(GLuint shaderProg, vbo VBO, dataWaveCompute dataDev, parameter Param);

//Free Memory
double GPUSimulationFreeMemory(dataWaveCompute *dataDev);
void cleanup();

//Event
// rendering callbacks
void display();
void keyboard(unsigned char key, int x, int y);
void mouse(int button, int state, int x, int y);
void motion(int x, int y);
void timerEvent(int value);


// GL functionality
bool initGL(int *argc, char **argv);

int timesUp( double endTime,double elapsedSimulation);
int frameOver( int targetFrame,int frame);

// declaration, forward
bool runTest(int argc, char **argv, char *ref_file);

#endif /* HEADER_H_ */


