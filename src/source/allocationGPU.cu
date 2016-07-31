#include "../../header/header.h"



double GPUSimulationAllocationMemory(dataWaveCompute *dataDev, dataWaveCompute dataHost){

		cudaSetDevice(0);
		float gpu_time=0.0;
		cudaEvent_t start,stop;
			cudaEventCreate( &start ) ;
			 cudaEventCreate( &stop ) ;
			 cudaEventRecord( start, 0 ) ;


		dataDev->dt=dataHost.dt;

		dataDev->Mesh=dataHost.Mesh;

		cudaMalloc((double**)&dataDev->h, dataDev->Mesh.NCells * sizeof(double));
		cudaMalloc((double**)&dataDev->u, dataDev->Mesh.NCells* sizeof(double));
		cudaMalloc((double**)&dataDev->v, dataDev->Mesh.NCells* sizeof(double));
		cudaMalloc((double**)&dataDev->hu, dataDev->Mesh.NCells* sizeof(double));
		cudaMalloc((double**)&dataDev->hv, dataDev->Mesh.NCells* sizeof(double));

		cudaMalloc((double**)&dataDev->hnew, dataDev->Mesh.NCells * sizeof(double));
		cudaMalloc((double**)&dataDev->unew, dataDev->Mesh.NCells* sizeof(double));
		cudaMalloc((double**)&dataDev->vnew, dataDev->Mesh.NCells* sizeof(double));
		cudaMalloc((double**)&dataDev->hunew, dataDev->Mesh.NCells* sizeof(double));
		cudaMalloc((double**)&dataDev->hvnew, dataDev->Mesh.NCells* sizeof(double));

		cudaMalloc((double**)&dataDev->Mesh.L, dataDev->Mesh.NCells *3* sizeof(double));
		cudaMalloc((int**)&dataDev->Mesh.EtoE, dataDev->Mesh.NCells *3* sizeof(int));
		cudaMalloc((int**)&dataDev->Mesh.EtoV, dataDev->Mesh.NCells *3* sizeof(int));
		cudaMalloc((int**)&dataDev->Mesh.VtoE, dataDev->Mesh.NNodes * dataDev->Mesh.maxVtoEconn* sizeof(int));
		cudaMalloc((int**)&dataDev->Mesh.VtoS, dataDev->Mesh.NNodes * dataDev->Mesh.maxVtoEconn* sizeof(int));


		cudaMalloc((double**)&dataDev->Mesh.nx, dataDev->Mesh.NCells *3* sizeof(double));
		cudaMalloc((double**)&dataDev->Mesh.ny, dataDev->Mesh.NCells *3* sizeof(double));
		cudaMalloc((double**)&dataDev->Mesh.AREA, dataDev->Mesh.NCells* sizeof(double));
		cudaMalloc((double**)&dataDev->Mesh.VertX, dataDev->Mesh.NNodes* sizeof(double));
		cudaMalloc((double**)&dataDev->Mesh.VertY, dataDev->Mesh.NNodes* sizeof(double));

		cudaMalloc((double**)&dataDev->Mesh.NormalFaces, dataDev->Mesh.NCells* sizeof(float3));

//		cudaMalloc((double**)&dataDev->z, dataDev->Mesh.NCells* sizeof(double));



		cudaMemcpy(dataDev->h, dataHost.h, dataDev->Mesh.NCells * sizeof(double), cudaMemcpyHostToDevice);
		cudaMemcpy(dataDev->u, dataHost.u, dataDev->Mesh.NCells * sizeof(double), cudaMemcpyHostToDevice);
		cudaMemcpy(dataDev->v, dataHost.v, dataDev->Mesh.NCells * sizeof(double), cudaMemcpyHostToDevice);
		cudaMemcpy(dataDev->hu, dataHost.hu, dataDev->Mesh.NCells * sizeof(double), cudaMemcpyHostToDevice);
		cudaMemcpy(dataDev->hv, dataHost.hv, dataDev->Mesh.NCells * sizeof(double), cudaMemcpyHostToDevice);


		cudaMemcpy(dataDev->Mesh.L, dataHost.Mesh.L, dataDev->Mesh.NCells * 3*sizeof(double), cudaMemcpyHostToDevice);
		cudaMemcpy(dataDev->Mesh.EtoE, dataHost.Mesh.EtoE, dataDev->Mesh.NCells * 3*sizeof(int), cudaMemcpyHostToDevice);
		cudaMemcpy(dataDev->Mesh.EtoV, dataHost.Mesh.EtoV, dataDev->Mesh.NCells * 3*sizeof(int), cudaMemcpyHostToDevice);
		cudaMemcpy(dataDev->Mesh.VtoE, dataHost.Mesh.VtoE, dataDev->Mesh.NNodes * dataDev->Mesh.maxVtoEconn*sizeof(int), cudaMemcpyHostToDevice);
		cudaMemcpy(dataDev->Mesh.VtoS, dataHost.Mesh.VtoS, dataDev->Mesh.NNodes * dataDev->Mesh.maxVtoEconn*sizeof(int), cudaMemcpyHostToDevice);

		cudaMemcpy(dataDev->Mesh.nx, dataHost.Mesh.nx, dataDev->Mesh.NCells * 3*sizeof(double), cudaMemcpyHostToDevice);
		cudaMemcpy(dataDev->Mesh.ny, dataHost.Mesh.ny, dataDev->Mesh.NCells * 3*sizeof(double), cudaMemcpyHostToDevice);
		cudaMemcpy(dataDev->Mesh.AREA, dataHost.Mesh.AREA, dataDev->Mesh.NCells * sizeof(double), cudaMemcpyHostToDevice);
//		cudaMemcpy(dataDev->z, dataHost.z, dataDev->Mesh.NCells * sizeof(double), cudaMemcpyHostToDevice);
	//			printf("\nTest... count %doperator %lf", dataDev->Mesh.NCells, dataHost.Mesh.AREA[221]);
	//			exit(-1);

		cudaMemcpy(dataDev->Mesh.VertX, dataHost.Mesh.VertX, dataDev->Mesh.NNodes * sizeof(double), cudaMemcpyHostToDevice);
		cudaMemcpy(dataDev->Mesh.VertY, dataHost.Mesh.VertY, dataDev->Mesh.NNodes * sizeof(double), cudaMemcpyHostToDevice);


		 cudaEventRecord( stop, 0 ) ;
		 cudaEventSynchronize( stop ) ;
		cudaEventElapsedTime( &gpu_time,	start, stop ) ;
		cudaEventDestroy( start ) ;
		cudaEventDestroy( stop ) ;

		return (double)gpu_time/1000.0;

}


int threadAllocation(int blockAllocation, gpuThread *GPUThread, dataWaveCompute dataDev)
{
	dim3 block(blockAllocation);
	dim3 grid1 ((dataDev.Mesh.NCells+ block.x-1)/block.x);
	dim3 grid2((dataDev.Mesh.NCells+ block.x-1)/block.x);

	GPUThread->grid1=grid1;
	GPUThread->grid2=grid2;
	GPUThread->block=block;

	return 1;
}
