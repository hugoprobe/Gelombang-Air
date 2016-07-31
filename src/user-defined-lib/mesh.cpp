/*The Codes in this file are a modification and development from : Team Warburton */
/*Kode dalam file ini merupakan modifikasi dan pengembangan dari program milik Tim Warburton */
/* www.caam.rice.edu/~caam452. */

#include "mesh.h"


int imax(int *v, int L){
	int res = v[0];
	int i;
	for(i=1;i<L;++i)
		res=max(res,v[i]);
	return res;
}

int *ivector(int L){
	int *v=(int*) calloc(L,sizeof(int));
	//int *v=malloc(L*sizeof(int));
	return v;
}

double *dvector(int L){
	double *v=(double*) calloc(L,sizeof(double));
	return v;
}

void dvectorprint(char *message, double *d, int L){
	int i;
	fprintf(stdout, "%s ---start---\n",message);
	for(i=0;i<L;++i){
		fprintf(stdout,"%d: %lf\n",i,d[i]);
	}

	fprintf(stdout, "%s ---end---\n",message);
}



int readMeshFile(mesh *Mesh, char *title)
{
	int i;
//	timeExp=readForExp();

	Mesh->NFaces=3;


// Baca jumlah simpul dan jumlah elemen
	FILE *Fid; //*fp
	char FileName[BUFSIZ], buf[BUFSIZ]; //, fname[BUFSIZ];

	sprintf(FileName, "/home/atma/cuda-workspace/Acoustic2D_FV2D/data/%s",title);
	if(!(Fid=fopen(FileName,"r"))){
		fprintf(stderr, "Could not load mesh file: %s\n", FileName);
		exit(-1);
	}

		//Baca format baris kosong
	for(i=0;i<6;i++){
		fgets(buf, BUFSIZ, Fid);
	}

	fgets(buf, BUFSIZ, Fid);
	sscanf(buf,"%d%d%d",&(Mesh->NNodes),&(Mesh->NCells), &Mesh->Wall.count);

	for(i=0; i<2;++i){
		fgets(buf, BUFSIZ, Fid);
	}


// Baca simpul dan cari titik X, Y maksimum dan minimum
	Mesh->VertX=dvector(Mesh->NNodes);
	Mesh->VertY=dvector(Mesh->NNodes);

	for(i=0;i<Mesh->NNodes;++i){
		fgets(buf,BUFSIZ,Fid);

		sscanf(buf, "%lf %lf", Mesh->VertX+i, Mesh->VertY+i);

		if(i>0){
			if(Mesh->Xmin>*(Mesh->VertX+i))Mesh->Xmin=*(Mesh->VertX+i);
			if(Mesh->Xmax>*(Mesh->VertX+i))Mesh->Xmax=*(Mesh->VertX+i);
			if(Mesh->Ymin>*(Mesh->VertY+i))Mesh->Ymin=*(Mesh->VertY+i);
			if(Mesh->Ymax>*(Mesh->VertY+i))Mesh->Ymax=*(Mesh->VertY+i);
		}else
		{
			Mesh->Xmax=Mesh->Xmin=*Mesh->VertX;
			Mesh->Ymax=Mesh->Ymin=*Mesh->VertY;
		}
	}
	for(i=0;i<2;++i){
			fgets(buf,BUFSIZ,Fid);
		}


//Baca elemen, relasi elemen ke verteks
	Mesh->EtoV=ivector(Mesh->NFaces*Mesh->NCells);

	for(int k=0;k<Mesh->NCells;++k){
		Mesh->EtoV[Mesh->NFaces*k+0]=MESH_FACE_NO_NEIGHBOUR;
		Mesh->EtoV[Mesh->NFaces*k+1]=MESH_FACE_NO_NEIGHBOUR;
		Mesh->EtoV[Mesh->NFaces*k+2]=MESH_FACE_NO_NEIGHBOUR;

	  fgets(buf,BUFSIZ,Fid);

	  sscanf(buf, "%d %d %d",
			  Mesh->EtoV+(Mesh->NFaces*k+0),
			  Mesh->EtoV+(Mesh->NFaces*k+1),
			  Mesh->EtoV+(Mesh->NFaces*k+2));

	}

//Baca dinding
	Mesh->Wall.Point1=new float3[Mesh->Wall.count];
	Mesh->Wall.Point2=new float3[Mesh->Wall.count];

	 fgets(buf,BUFSIZ,Fid);
	 fgets(buf,BUFSIZ,Fid);
//		 normalWall=  new float3[Mesh->Wall.count*2*3];

	 for(int nw=0;nw<Mesh->Wall.count;nw++)
	 {
		 float wallHeight;
		 fgets(buf,BUFSIZ,Fid);
		 sscanf(buf, "%f %f %f %f %f",
				 &(Mesh->Wall.Point1+nw)->x,
				 &(Mesh->Wall.Point1+nw)->y,
				 &(Mesh->Wall.Point2+nw)->x,
				 &(Mesh->Wall.Point2+nw)->y,
				 &wallHeight);
		 Mesh->Wall.Point1[nw].z=wallHeight;
		 Mesh->Wall.Point2[nw].z=wallHeight;


	 }

	/* now close .neu file */
	fclose(Fid);

	return 1;
}


void	setEtoV(mesh *Mesh, int *Nelmts)
{
	int va,vb,vc;


	// printf("\nWall Count1 = %d", Wall.count  );
	for(int k=0;k<Mesh->NCells ;++k){
		va=Mesh->EtoV[Mesh->NFaces*k+0];
		vb=Mesh->EtoV[Mesh->NFaces*k+1];
		vc=Mesh->EtoV[Mesh->NFaces*k+2];

		Nelmts[va]=Nelmts[va]+1;
		Nelmts[vb]=Nelmts[vb]+1;
		Nelmts[vc]=Nelmts[vc]+1;
	}

	Mesh->maxVtoEconn=imax(Nelmts,Mesh->NNodes)+1;

}

void 	setVtoE_VtoS(mesh *Mesh, int *Nelmts)
{
	int va,vb,vc;

	/* reset Nelmts per node counter */
	Mesh->VtoE = ivector(Mesh->maxVtoEconn*Mesh->NNodes);
	Mesh->VtoS = ivector(Mesh->maxVtoEconn*Mesh->NNodes);
	memset(Mesh->VtoE,-1, sizeof(int)*Mesh->maxVtoEconn*Mesh->NNodes);
	memset(Mesh->VtoS,-1, sizeof(int)*Mesh->maxVtoEconn*Mesh->NNodes);


	for(int i=0;i<Mesh->NNodes;i++)Nelmts[i]=0;

	/* invert umElmtToNode map */
	for(int k=0; k<Mesh->NCells; ++k){

		va=Mesh->EtoV[Mesh->NFaces*k+0];
		vb=Mesh->EtoV[Mesh->NFaces*k+1];
		vc=Mesh->EtoV[Mesh->NFaces*k+2];
		Mesh->VtoE[Mesh->maxVtoEconn*va+Nelmts[va]]=k;
		Mesh->VtoE[Mesh->maxVtoEconn*vb+Nelmts[vb]]=k;
		Mesh->VtoE[Mesh->maxVtoEconn*vc+Nelmts[vc]]=k;

		Mesh->VtoS[Mesh->maxVtoEconn*va+Nelmts[va]]=Mesh->NFaces*k+0;
		Mesh->VtoS[Mesh->maxVtoEconn*vb+Nelmts[vb]]=Mesh->NFaces*k+1;
		Mesh->VtoS[Mesh->maxVtoEconn*vc+Nelmts[vc]]=Mesh->NFaces*k+2;


		Nelmts[va]=Nelmts[va]+1;
		Nelmts[vb]=Nelmts[vb]+1;
		Nelmts[vc]=Nelmts[vc]+1;


		}

}

void	setEtoE(mesh *Mesh, int *Nelmts)
{
	int i,j,k;
	int Nbc, *bcelements;
	int va,vb,vc, Nva, Nvc, Nvb, eida, eidb,eidc;


	/* need to create umElmtToElmt */
	Mesh->EtoE=ivector(Mesh->NFaces*Mesh->NCells);
	for(k=0;k<Mesh->NCells;++k)
	{
		va=Mesh->EtoV[Mesh->NFaces*k+0];
		vb=Mesh->EtoV[Mesh->NFaces*k+1];
		vc=Mesh->EtoV[Mesh->NFaces*k+2];

		Nva=Nelmts[va];
		Nvb=Nelmts[vb];
		Nvc=Nelmts[vc];

		Mesh->EtoE[Mesh->NFaces*k+0]=-1;

		for(i=0; i<Nva;++i){
			eida=Mesh->VtoE[Mesh->maxVtoEconn*va+i];
			if(eida!=k){
				for(j=0;j<Nvb;++j){
					eidb=Mesh->VtoE[Mesh->maxVtoEconn*vb+j];
					if(eida==eidb){
						Mesh->EtoE[Mesh->NFaces*k+0]=eida;
					}
				}

			}
		}

		Mesh->EtoE[Mesh->NFaces*k+1]=-1;
		for(i=0; i<Nvb;++i){
			eidb=Mesh->VtoE[Mesh->maxVtoEconn*vb+i];
			if(eidb!=k){
				for(j=0;j<Nvc;++j){
					eidc=Mesh->VtoE[Mesh->maxVtoEconn*vc+j];
					if(eidb==eidc){
						Mesh->EtoE[Mesh->NFaces*k+1]=eidb;
					}
				}

			}
		}


		Mesh->EtoE[Mesh->NFaces*k+2]=-1;
		for(i=0; i<Nva;++i){
			eida=Mesh->VtoE[Mesh->maxVtoEconn*va+i];
			if(eida!=k){
				for(j=0;j<Nvc;++j){
					eidc=Mesh->VtoE[Mesh->maxVtoEconn*vc+j];
					if(eida==eidc){
						Mesh->EtoE[Mesh->NFaces*k+2]=eida;
					}
				}

			}
		}
	}


	/* find elements sitting at boundary on the inflow */
	Nbc=0;

	for(k=0;k<Mesh->NCells;++k){
		for(i=0;i<Mesh->NFaces;++i){
			if(Mesh->EtoE[Mesh->NFaces*k+i]==-1){
				Nbc=Nbc+1;
			}
		}
	}

	bcelements=ivector(Nbc);
	Nbc=0;


	for(k=0;k<Mesh->NCells;++k){

		for(i=0;i<Mesh->NFaces;++i){
			if(Mesh->EtoE[Mesh->NFaces*k+i]==MESH_FACE_NO_NEIGHBOUR){
				bcelements[Nbc]=k;
				Nbc=Nbc+1;
				Mesh->EtoE[Mesh->NFaces*k+i]=k;

			}


		}

	}



}

void 	setMeshRelation(mesh *Mesh)
{
	//harus urut
	int *Nelmts= ivector(Mesh->NNodes);
	setEtoV(Mesh, Nelmts);
	setVtoE_VtoS(Mesh, Nelmts);
	setEtoE(Mesh, Nelmts);

}

void setMeshInformation(mesh *Mesh)
{

	double dx, dy;
	double a,b,c,s;

	Mesh->nx=dvector(Mesh->NCells*3);
	Mesh->ny=dvector(Mesh->NCells*3);
	Mesh->L=dvector(Mesh->NCells*3);
	Mesh->AREA=dvector(Mesh->NCells);

	//Mesh->z=dvector(Mesh->NCells);

	Mesh->X=dvector(Mesh->NCells*3);
	Mesh->Y=dvector(Mesh->NCells*3);
	Mesh->CX=dvector(Mesh->NCells);
	Mesh->CY=dvector(Mesh->NCells);
	/*vertex location for each vertex of each element */

	for(int k=0; k<Mesh->NCells; ++k){
		for(int i=0;i<Mesh->NFaces;++i){
			Mesh->X[Mesh->NFaces*k+i]=Mesh->VertX[Mesh->EtoV[Mesh->NFaces*k+i]];
			Mesh->Y[Mesh->NFaces*k+i]=Mesh->VertY[Mesh->EtoV[Mesh->NFaces*k+i]];

		}

		for(int i=0;i<Mesh->NFaces;++i){
			/*compute edge lengths*/
			dx=(Mesh->X[Mesh->NFaces*k+(i+1)%Mesh->NFaces]-Mesh->X[Mesh->NFaces*k+i]);
			dy=(Mesh->Y[Mesh->NFaces*k+(i+1)%Mesh->NFaces]-Mesh->Y[Mesh->NFaces*k+i]);
			Mesh->L[Mesh->NFaces*k+i]=sqrt(dx*dx+dy*dy);

			Mesh->nx[Mesh->NFaces*k+i]=dy;
			Mesh->ny[Mesh->NFaces*k+i]=-dx;

			Mesh->nx[Mesh->NFaces*k+i]/=Mesh->L[Mesh->NFaces*k+i];
			Mesh->ny[Mesh->NFaces*k+i]/=Mesh->L[Mesh->NFaces*k+i];
		}
		a=Mesh->L[Mesh->NFaces*k+0];
		b=Mesh->L[Mesh->NFaces*k+0];
		c=Mesh->L[Mesh->NFaces*k+0];
		s=(1/2.)*(a+b+c);

		Mesh->AREA[k]=sqrt(s*(s-a)*(s-b)*(s-c));

		/* cell center coordinates */
		Mesh->CX[k]= (1./(double)3)*(Mesh->X[3*k+0]+Mesh->X[3*k+1] + Mesh->X[3*k +2]);
		Mesh->CY[k]= (1./(double)3)*(Mesh->Y[3*k+0]+Mesh->Y[3*k+1] + Mesh->Y[3*k +2]);

	}


}

