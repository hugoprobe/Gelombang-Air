#ifndef MESH_H_
#define MESH_H_
#include <vector_types.h>
#include <stdio.h>
#define MESH_FACE_NO_NEIGHBOUR -1

typedef struct
{
	float3 *Point1, *Point2;
	float bold;
	int count;

}wall;


typedef struct{
	int *VtoE;
	int *EtoE;
	int *EtoV;
	int *VtoS;

	int NCells;
	int NNodes;
	int NFaces;
	double *VertX, *VertY;
	double Xmin, Ymin, Xmax, Ymax;
	int maxVtoEconn;
	double *AREA, *L, *nx, *ny, *X, *Y, *CX, *CY;
	float3 *NormalFaces;
	wall Wall;
}mesh;


int imax(int *v, int L);
int *ivector(int L);

double *dvector(int L);

void dvectorprint(char *message, double *d, int L);

//double * readForExp();
int 	readMeshFile(mesh *Mesh, char *title);
void	setEtoV(mesh *Mesh, int *Nelmts);
void 	setVtoE_VtoS(mesh *Mesh, int *Nelmts);
void	setEtoE(mesh *Mesh, int *Nelmts);
void 	setMeshRelation(mesh *Mesh);
void 	setMeshInformation(mesh *Mesh);


#endif
