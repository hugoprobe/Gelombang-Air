#include "../../header/header.h"

inline __host__ __device__ int isIn(int elem)
{
	unsigned int indicesLd[12]={21818,21822,21826,21830,21834,21838,21842,21846,21850,21854,21858,21862};
	unsigned int indicesRd[12]={24412,24416,24420,24424,244428,24432,24436,24440,24444,24448,24452,24456};

	for(int i =0;i<12;i++)
	{
		if(elem==indicesLd[i] || elem==indicesRd[i])
		{
			return 1;

		}

	}
	return 0;
}


inline __host__ __device__ double calculate_a(double *a_plus, double *a_min, double uj, double uk, double hj, double hk)
{
	*a_plus=max(uj+sqrt(g*hj),uk+sqrt(g*hk));
	*a_plus=max(*a_plus,0.0);
	*a_min=min(uj-sqrt(g*hj),uk-sqrt(g*hk));
	*a_min=min(*a_min,0.0);
	return 1;
}

inline __host__ __device__ double calculate_H(double HUj, double HUk, double a_plus, double a_min, double Uj,double Uk)
{
	double da=a_plus-a_min;
	if(da<10e-8) return 0.5*(HUj-HUk);
	return ((a_plus*HUj - a_min*HUk)/da + a_plus*a_min/da*(Uk-Uj));

}

inline __host__ __device__ double calculate_Unew(double Uold, double EFluxCrossL, double dt, double A)
{
	return (Uold-dt*EFluxCrossL/A);
}

inline __host__ __device__ int isReflectif(int nb, int k)
{
	return (nb==k || isIn(nb));
}


__global__ void kernelcopy(
		double *h1, double *u1, double *v1, double *hu1, double *hv1,
		double *h, double *u, double *v, double *hu, double *hv, int Nelems)
{
	unsigned int idx=threadIdx.x + blockIdx.x * blockDim.x;

	if(idx>=Nelems) return;

	h[idx]=h1[idx];
	hu[idx]=hu1[idx];
	hv[idx]=hv1[idx];

	u[idx]=hu[idx]*1.0/(h[idx]*1.0);
	v[idx]=hv[idx]*1.0/(h[idx]*1.0);


}


__global__ void kernelFluxCalculation( int *EtoV,
		double *h1, double *u1, double *v1, double *hu1, double *hv1,
		double *h, double *u, double *v, double *hu, double *hv,

		double *L, int *EtoE, double *normx, double *normy, double *AREA, double dt, int Nelems)

{
	unsigned int idx=threadIdx.x + blockIdx.x*blockDim.x;
	if(idx>=Nelems) return;
	//if(h1[idx]>0.01 && h1[idx]<0.3)printf("\n Test %d %lf  %lf  %lf",idx, v[idx],h1[idx],hu[idx]);
	double hj, hk, uj, uk, vj,vk, huj, huk, hvj, hvk;
	double a_plus, a_min;
	double HUj, HUk, nx, ny, l, A;
	double Flux_h=0.0, Flux_hu=0.0, Flux_hv=0.0;


	//fill common elements
	hj=h[idx];
	uj=u[idx];
	vj=v[idx];
	huj=hu[idx];
	hvj=hv[idx];
	A=AREA[idx];
	uj=huj/hj;
	vj=hvj/hj;




	//In every triangles, visit its neighbor, using this loop
	for(int n=0; n<3;n++)
	{
			//using k to get the mapping index of neighbor(nb) element on EtoE
			//save in nb
			int k = idx*3+ n;
			int nb= EtoE[k];



			//fill neighbor elements

			nx=normx[k];

			ny=normy[k];
			l=L[k];

			hk=h[nb];
							uk=u[nb];
							vk=v[nb];
							huk=hu[nb];
							hvk=hv[nb];
							uk=huk/hk;
							vk=hvk/hk;

			if(nb==idx)
			{

				hk=hj;
				uk=-uj;
				vk=-vj;
				huk=-huj;
				hvk=-hvj;

			}



			//Calculate wave speed
		//	calculate_a(&a_plus, &a_min,sqrt(uj*uj+vj*vj), sqrt(uk*uk+vk*vk),hj,hk);

		//	calculate_a(&a_plus, &a_min,uj, uk,hj,hk);
			calculate_a(&a_plus, &a_min,nx*uj +ny*vj, nx*uk+ny*vk,hj,hk);

			//Calculate Height Flux
			HUj= huj*nx + hvj*ny;
			HUk= huk*nx + hvk*ny;
			Flux_h+=l*calculate_H(HUj, HUk, a_plus, a_min, hj, hk);

			//Calculate X momentum Flux
			HUj = (huj*uj + 0.5*g*hj*hj)*nx;
			HUj+= (huj*vj)*ny;
			HUk = (huk*uk + 0.5*g*hk*hk)*nx;
			HUk+= (huk*vk)*ny;
		//	Flux_hu+=l*calculate_H(HUj, HUk, a_plus, a_min, huj, isReflectif(nb,idx)?-huk:huk);
			Flux_hu+=l*calculate_H(HUj, HUk, a_plus, a_min, huj, huk);

			//Calculate Y momentum Flux
			HUj = (hvj*uj)*nx;
			HUj+= (hvj*vj + 0.5*g*hj*hj)*ny;
			HUk = (hvk*uk)*nx;
			HUk+= (hvk*vk + 0.5*g*hk*hk)*ny;
		//	Flux_hv+=l*calculate_H(HUj, HUk, a_plus, a_min, hvj,  isReflectif(nb,idx)?-hvk:hvk);
			Flux_hv+=l*calculate_H(HUj, HUk, a_plus, a_min, hvj,  hvk);

	}



	h1[idx]=calculate_Unew(hj,Flux_h, dt,A) ;
	hu1[idx]=calculate_Unew(huj, Flux_hu,dt,A);
	hv1[idx]=calculate_Unew(hvj, Flux_hv,dt,A);



}




double computeGPU(int iteration , gpuThread GPUThread,   dataWaveCompute *dataDev)
{

	for(int i=0;i<iteration;i++)
	{

		kernelFluxCalculation<<<GPUThread.grid1,GPUThread.block>>>( dataDev->Mesh.EtoV,
				dataDev->hnew, dataDev->unew, dataDev->vnew, dataDev->hunew, dataDev->hvnew,
				dataDev->h, dataDev->u, dataDev->v, dataDev->hu, dataDev->hv,
				dataDev->Mesh.L,
				dataDev->Mesh.EtoE, dataDev->Mesh.nx, dataDev->Mesh.ny,
				dataDev->Mesh.AREA, dataDev->dt, dataDev->Mesh.NCells);

		kernelcopy<<<GPUThread.grid1,GPUThread.block>>>(dataDev->hnew,dataDev->unew, dataDev->vnew, dataDev->hunew, dataDev->hvnew,
									dataDev->h, dataDev->u, dataDev->v, dataDev->hu, dataDev->hv,dataDev->Mesh.NCells);
	}


	return 0;


}
