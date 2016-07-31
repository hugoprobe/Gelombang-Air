#include "../../header/header.h"
#include "../../user defined lib/vbo.h"



void createMeshIndexBuffer(GLuint *id, mesh Mesh)
		//int *EtoV, int Nelems, int NNodes)
{
    int i, size = (Mesh.NCells+Mesh.Wall.count*6)*3*sizeof(GLuint);
    int endPosVertex=Mesh.NNodes;
    // create index buffer
    glGenBuffersARB(1, id);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, *id);
    glBufferDataARB(GL_ELEMENT_ARRAY_BUFFER, size, 0, GL_STATIC_DRAW);

    // fill with indices for rendering mesh as triangle strips
    GLuint *indices = (GLuint *) glMapBuffer(GL_ELEMENT_ARRAY_BUFFER, GL_WRITE_ONLY);

    if (!indices)
    {
        return;
    }

    for (i=0; i<Mesh.NCells*3; i++)
    {
    	*indices++=Mesh.EtoV[i];
    	//printf("\nEtoV %d %d %d", i, i%3,Mesh.EtoV[i]);
    }
    for(i=0; i<Mesh.Wall.count*6;i++)
    {
    	*indices++=endPosVertex++;
    }


    glUnmapBuffer(GL_ELEMENT_ARRAY_BUFFER);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

}

// create fixed vertex buffer to store mesh vertices
void createMeshPositionVBO(GLuint *id, struct cudaGraphicsResource **vertex_pos, mesh Mesh)
		//double * VertX, double *VertY, int Nnodes)
{
    createVBO2(id, (Mesh.NNodes+Mesh.Wall.count*6)*4*sizeof(float));


    glBindBuffer(GL_ARRAY_BUFFER, *id);
    float *pos = (float *) glMapBuffer(GL_ARRAY_BUFFER, GL_WRITE_ONLY);

    if (!pos)
    {
        return;
    }

    for (int idx=0; idx<Mesh.NNodes; idx++)
    {

     //       float u = x / (float)(w-1);
      //      float v = y / (float)(h-1);
            *pos++ = Mesh.VertX[idx];
            *pos++ = 0.0f;
            *pos++ = Mesh.VertY[idx];
            *pos++ = 1.0f;

        //    printf("\nCoor %lf    %lf", Mesh.VertX[idx], Mesh.VertY[idx]);

    }



    for (int idx=0; idx<Mesh.Wall.count; idx++)
    {
    	float3 v0=make_float3(Mesh.Wall.Point1[idx].x,Mesh.Wall.Point1[idx].y,0);

    	float3 edge1=Mesh.Wall.Point2[idx]-Mesh.Wall.Point1[idx];
    	float3 edge2=v0-Mesh.Wall.Point1[idx];

    	float3 normal=cross(edge1,edge2);
/*
    	for(int i=0;i<6;i++)
    		normalWall[idx*6+i]=normal;
*/

            *pos++ =  Mesh.Wall.Point1[idx].x;
            *pos++ = 0.0f;
            *pos++ = Mesh.Wall.Point1[idx].y;
            *pos++=1.0;

            *pos++ =  Mesh.Wall.Point1[idx].x;
            *pos++ = Mesh.Wall.Point1[idx].z;
       //     printf("\n%f",*(pos-1));
            *pos++ = Mesh.Wall.Point1[idx].y;
            *pos++=1.0;

            *pos++ =  Mesh.Wall.Point2[idx].x;
            *pos++ = Mesh.Wall.Point2[idx].z;
        //    printf("\n%f",*(pos-1));
            *pos++ = Mesh.Wall.Point2[idx].y;
            *pos++=1.0;





            *pos++ =  Mesh.Wall.Point1[idx].x;
		    *pos++ = 0.0f;
		    *pos++ = Mesh.Wall.Point1[idx].y;
		    *pos++=1.0;

            *pos++ =  Mesh.Wall.Point2[idx].x;
            *pos++ = 0.0f;
            *pos++ = Mesh.Wall.Point2[idx].y;

            *pos++=1.0;


            *pos++ =  Mesh.Wall.Point2[idx].x;
			*pos++ = Mesh.Wall.Point2[idx].z;
		//	printf("\n%f",*(pos-1));
			*pos++ = Mesh.Wall.Point2[idx].y;
			*pos++=1.0;





    }

    glUnmapBuffer(GL_ARRAY_BUFFER);
    glBindBuffer(GL_ARRAY_BUFFER, 0);


    checkCudaErrors(cudaGraphicsGLRegisterBuffer(vertex_pos, *id, cudaGraphicsMapFlagsNone));
}

void initVBO(vbo *VBO, mesh Mesh)
{
    createVBO2(&VBO->VertexNormalBuffer, (Mesh.NNodes+Mesh.Wall.count*6)*sizeof(float3));

		       glBindBuffer(GL_ARRAY_BUFFER, VBO->VertexNormalBuffer);
		             float3 *pos = (float3 *) glMapBuffer(GL_ARRAY_BUFFER, GL_WRITE_ONLY);

		             if (!pos)
		             {
		               //  return;

		             }else
		             {

		            	 pos=pos+Mesh.NNodes;

		            	 for(int ii=0;ii<Mesh.Wall.count;ii++)
		            	 {
		            		 int s=-1;
		            		 if(ii%3<3)s*=-1;
		            		 float3 v0=make_float3(Mesh.Wall.Point1[ii].x,Mesh.Wall.Point1[ii].y,0);
		            		 float3 edge1=Mesh.Wall.Point2[ii]-Mesh.Wall.Point1[ii];
							float3 edge2=v0-Mesh.Wall.Point1[ii];

							float3 normal=make_float3(0,0,0);//cross(edge2,edge1);

							for(int i=0;i<6;i++)

								*pos++=normal;


						//	make_float3
		            	 }

		             }
				 glUnmapBuffer(GL_ARRAY_BUFFER);
				 glBindBuffer(GL_ARRAY_BUFFER, 0);
				 //make_float3



		       checkCudaErrors(cudaGraphicsGLRegisterBuffer(&VBO->cuda_VertexNormal_resource, VBO->VertexNormalBuffer, cudaGraphicsMapFlagsWriteDiscard));

		      createVBO2(&VBO->signBuffer, Mesh.NNodes*sizeof(float));
		      checkCudaErrors(cudaGraphicsGLRegisterBuffer(&VBO->cuda_Sign_resource,VBO->signBuffer, cudaGraphicsMapFlagsWriteDiscard));

		      createMeshPositionVBO(&VBO->posVertexBuffer, &VBO->cuda_VertexPos_resource, Mesh);
	          createMeshIndexBuffer(&VBO->indexBuffer, Mesh);



}
