#include "../../header/header.h"



__global__ void kernelUpdateVertex(float4 *pos,int *VtoE, int *VtoS, double *VertX, double *VertY, double *p , int maxconn, int Nnodes)
{


	unsigned int idx=threadIdx.x + blockIdx.x * blockDim.x;

	double w;

	int i, k;
	float sum=0;
	int ie;
	int iconn=0;
	if(idx>=Nnodes) return;



	k=idx*maxconn;
	for(i=0;  i < maxconn; i++)
	{

		ie = VtoE[k+i];
		if(ie==-1)break;
		sum=sum+p[ie];
		iconn++;


	}

	w=1.0*sum/iconn;


	pos[idx]=make_float4(pos[idx].x,w,pos[idx].z, .0f);


}

__global__ void kernelNormalFace(float4 *vertexPos, float3 *normalFace, int *EtoV, int Nelems)
{

	float3 edge1,edge2;
	int i1,i2,i3;

	unsigned int idx=threadIdx.x + blockIdx.x * blockDim.x;

	if(idx>=Nelems) return;

	i1 = EtoV[idx*3 + 0];
	i2 = EtoV[idx*3 + 1];
	i3 = EtoV[idx*3 + 2];


	edge1=operator-(make_float3(vertexPos[i2]),make_float3(vertexPos[i1]));
	edge2=operator-(make_float3(vertexPos[i3]),make_float3(vertexPos[i1]));



	normalFace[idx] = cross(edge2,edge1);


}

__global__ void kernelNormalVektor(float4 *vertexPos, float3 *normalVector, float3 *normalFace, int *VtoE, int maxconn, int Nnodes)
{
	unsigned int idx=threadIdx.x + blockIdx.x * blockDim.x;
	float3 vsum=make_float3(0.0,0.0,0.0);
	int i, k=idx*maxconn;
	if(idx>=Nnodes) return;

		for(i=0;  i < maxconn; i++)
		{

			int ie = VtoE[k+i];
			if(ie==-1)break;
			operator+=(vsum, normalFace[ie]);

		}

		normalVector[idx]=operator/(vsum,i);
}


void computeVisualization(vbo VBO, parameter Param,gpuThread  GPUThread,  dataWaveCompute *dataDev, dataWaveCompute dataHost)
{
	float4 *vertexPos;
	float3 *nptr;
	size_t num_bytes;

	if(Param.device==DEVICE_CPU) GPUSimulationAllocationMemory(dataDev,dataHost);


	checkCudaErrors(cudaGraphicsMapResources(1, &VBO.cuda_VertexNormal_resource, 0));
		    checkCudaErrors(cudaGraphicsResourceGetMappedPointer((void **)&nptr, &num_bytes, VBO.cuda_VertexNormal_resource));


		    checkCudaErrors(cudaGraphicsMapResources(1, &VBO.cuda_VertexPos_resource, 0));
		    checkCudaErrors(cudaGraphicsResourceGetMappedPointer((void **)&vertexPos, &num_bytes,
		    		VBO.cuda_VertexPos_resource));

		kernelUpdateVertex<<<GPUThread.grid2,GPUThread.block>>>(vertexPos,dataDev->Mesh.VtoE, dataDev->Mesh.VtoS, dataDev->Mesh.VertX,
						dataDev->Mesh.VertY, dataDev->h, dataDev->Mesh.maxVtoEconn,	dataDev->Mesh.NNodes);



		kernelNormalFace<<<GPUThread.grid1,GPUThread.block>>>(vertexPos, dataDev->Mesh.NormalFaces, dataDev->Mesh.EtoV, dataDev->Mesh.NCells);

		kernelNormalVektor<<<GPUThread.grid2,GPUThread.block>>>(vertexPos, nptr, dataDev->Mesh.NormalFaces, dataDev->Mesh.VtoE,
						dataDev->Mesh.maxVtoEconn, dataDev->Mesh.NNodes);

		checkCudaErrors(cudaGraphicsUnmapResources(1, &VBO.cuda_VertexNormal_resource, 0));


		 checkCudaErrors(cudaGraphicsUnmapResources(1, &VBO.cuda_VertexPos_resource, 0));
	 if(Param.device==DEVICE_CPU)  GPUSimulationFreeMemory(dataDev);


}


