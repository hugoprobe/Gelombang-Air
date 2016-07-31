#include "../../header/header.h"



int InitMesh(mesh * Mesh, char *title)
{

	readMeshFile(Mesh,title);
	setMeshRelation(Mesh);
	setMeshInformation(Mesh);

	return 1;

}
