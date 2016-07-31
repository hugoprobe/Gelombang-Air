#include "../../header/header.h"




int InitDataComputation(dataWaveCompute *data, double dt)
{



	data->h=dvector(data->Mesh.NCells);
	data->u=dvector(data->Mesh.NCells);
	data->v=dvector(data->Mesh.NCells);
	data->hu=dvector(data->Mesh.NCells);
	data->hv=dvector(data->Mesh.NCells);


	data->hnew=dvector(data->Mesh.NCells);
	data->unew=dvector(data->Mesh.NCells);
	data->vnew=dvector(data->Mesh.NCells);
	data->hunew=dvector(data->Mesh.NCells);
	data->hvnew=dvector(data->Mesh.NCells);




	data->dt=dt;

	for(int k=0;k<data->Mesh.NCells;++k){


	//	data->h[k]=100.0;




		if(data->Mesh.CX[k]<=0.4)
		{
			data->h[k]=0.3;
		}
		else if (data->Mesh.CX[k]<=0.4+0.5)
		{
			data->h[k]=0.01;
		}
		else  if(data->Mesh.CX[k]<0.4+0.5+0.12)
		{
			if(data->Mesh.CY[k]>=0.25 && data->Mesh.CY[k]<=0.25+0.12)
			{
				data->h[k]=0.75;
			}
			else
				data->h[k]=0.01;
		}else
			data->h[k]=0.01;




		data->u[k]=0.0;
		data->v[k]=0.0;
		data->hu[k]=0.0;
		data->hv[k]=0.0;


	}




	return 1;

}
