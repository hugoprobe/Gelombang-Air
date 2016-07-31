#include "../../header/header.h"


double GPUSimulationFreeMemory(dataWaveCompute *dataDev)
{



				float gpu_time=0.0;
				cudaEvent_t start,stop;
					cudaEventCreate( &start ) ;
					 cudaEventCreate( &stop ) ;
					 cudaEventRecord( start, 0 ) ;


		cudaFree(dataDev->h);
		cudaFree(dataDev->u);
		cudaFree(dataDev->v);
		cudaFree(dataDev->hu);
		cudaFree(dataDev->hv);
		cudaFree(dataDev->z);


		cudaFree(dataDev->hnew);
		cudaFree(dataDev->unew);
		cudaFree(dataDev->vnew);
		cudaFree(dataDev->hunew);
		cudaFree(dataDev->hvnew);

		cudaFree(dataDev->Mesh.L);
		cudaFree(dataDev->Mesh.EtoE);
		cudaFree(dataDev->Mesh.EtoV);
		cudaFree(dataDev->Mesh.VtoE);
		cudaFree(dataDev->Mesh.VtoS);
		cudaFree(dataDev->Mesh.NormalFaces);
		cudaFree(dataDev->Mesh.nx);
		cudaFree(dataDev->Mesh.ny);
		cudaFree(dataDev->Mesh.VertX);
		cudaFree(dataDev->Mesh.VertY);
		cudaFree(dataDev->Mesh.AREA);

		 cudaEventRecord( stop, 0 ) ;
		 cudaEventSynchronize( stop ) ;
		cudaEventElapsedTime( &gpu_time,	start, stop ) ;
		cudaEventDestroy( start ) ;
		cudaEventDestroy( stop ) ;

		cudaDeviceSynchronize();


		return (double)gpu_time/1000.0;
}
